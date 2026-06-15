import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:new_invoice_generator/models/address.dart';
import 'package:new_invoice_generator/models/customer.dart';
import 'package:new_invoice_generator/utils/import_normalizer.dart';

/// A parsed customer row + any warnings raised while normalising it.
class ParsedCustomer {
  final Customer customer;
  final List<String> warnings;
  bool selected;
  ParsedCustomer(
    this.customer, {
    this.warnings = const [],
    this.selected = true,
  });
}

class CustomerImportService {
  /// Parse an .xlsx byte buffer (e.g. a Cognito Forms export) into customers.
  /// Maps columns by header name so column order doesn't matter, and tolerates
  /// the common Cognito header set (Name_First, Address_State, etc.).
  static List<ParsedCustomer> parseXlsx(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final result = <ParsedCustomer>[];

    for (final table in excel.tables.values) {
      if (table.rows.isEmpty) continue;

      // Build a header → column-index map from the first non-empty row
      final headerRow = table.rows.first;
      final headers = <String, int>{};
      for (var i = 0; i < headerRow.length; i++) {
        final h = _cellString(headerRow[i]).trim().toLowerCase();
        if (h.isNotEmpty) headers[h] = i;
      }

      // Helper to read a cell by any of several candidate header names
      String read(List<String> candidates, List<dynamic> row) {
        for (final c in candidates) {
          final idx = headers[c.toLowerCase()];
          if (idx != null && idx < row.length) {
            final v = _cellString(row[idx]).trim();
            if (v.isNotEmpty) return v;
          }
        }
        return '';
      }

      for (var r = 1; r < table.rows.length; r++) {
        final row = table.rows[r];
        if (row.every((c) => _cellString(c).trim().isEmpty)) continue;

        // Name — try first/last, then a single "name" column
        final first = read([
          'name_first',
          'first name',
          'first',
          'firstname',
        ], row);
        final last = read(['name_last', 'last name', 'last', 'lastname'], row);
        var name = ImportNormalizer.fullName(first, last);
        if (name.isEmpty) {
          name = read(['name', 'customer', 'customer name', 'full name'], row);
        }
        // Skip rows with no name at all
        if (name.isEmpty) continue;

        final email = read(['email', 'email address', 'e-mail'], row);
        final rawPhone = read([
          'phone',
          'phone number',
          'telephone',
          'mobile',
        ], row);
        final line1 = read([
          'address_line1',
          'address line 1',
          'address',
          'street',
        ], row);
        final line2 = read([
          'address_line2',
          'address line 2',
          'apt',
          'unit',
        ], row);
        final city = read(['address_city', 'city', 'town'], row);
        final state = read([
          'address_state',
          'state',
          'province',
          'province/state',
          'region',
        ], row);
        final postal = read([
          'address_postalcode',
          'postal code',
          'postal',
          'zip',
          'zip code',
        ], row);
        final countryRaw = read(['address_country', 'country'], row);
        final countryCode = read(['address_countrycode', 'country code'], row);

        final warnings = <String>[];

        // Normalise
        final normProvince = ImportNormalizer.province(state);
        final normCountry = ImportNormalizer.country(
          countryRaw,
          countryCode: countryCode,
        );
        final normPostal = ImportNormalizer.postalCode(postal);
        final normPhone = ImportNormalizer.phone(
          rawPhone,
          countryCode: countryCode,
        );

        if (rawPhone.isNotEmpty && normPhone.isEmpty) {
          warnings.add('Phone "$rawPhone" could not be validated — left blank');
        }
        if (state.isNotEmpty &&
            normProvince != state &&
            normProvince.length == 2) {
          // (silent — successful normalisation)
        }
        if (email.isNotEmpty && !email.contains('@')) {
          warnings.add('Email "$email" looks invalid');
        }

        final customer = Customer(
          id: '',
          name: name,
          email: email,
          phone: normPhone,
          address: Address(
            line: ImportNormalizer.streetLine(line1, line2),
            city: city,
            province: normProvince,
            postalCode: normPostal,
            country: normCountry,
          ),
        );

        result.add(ParsedCustomer(customer, warnings: warnings));
      }
    }

    return result;
  }

  static String _cellString(dynamic cell) {
    if (cell == null) return '';
    // Excel package wraps values in Data objects
    try {
      final v = cell.value;
      if (v == null) return '';
      return v.toString();
    } catch (_) {
      return cell.toString();
    }
  }
}
