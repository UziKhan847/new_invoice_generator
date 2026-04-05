import 'package:flutter/material.dart';
import 'package:new_invoice_generator/models/invoice.dart';
import 'package:new_invoice_generator/services/pdf.dart';
import 'package:printing/printing.dart';

class QuickPdfPreview extends StatelessWidget {
  final Invoice invoice;
  const QuickPdfPreview({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
            onPressed: () async {
              final bytes = await PdfService.buildPdfBytes(invoice);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () async {
              final bytes = await PdfService.buildPdfBytes(invoice);
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'invoice_${invoice.invoiceNumber}.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => PdfService.buildPdfBytes(invoice),
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'invoice_${invoice.invoiceNumber}.pdf',
      ),
    );
  }
}