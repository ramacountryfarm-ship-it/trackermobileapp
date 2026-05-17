import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api_client.dart';

class InvoiceService {
  /// Downloads invoice PDF for [saleId] and opens the system share sheet.
  static Future<bool> shareInvoice(String saleId, String invoiceNum) async {
    try {
      final res = await ApiClient().dio.get<List<int>>(
        '/sales/$saleId/invoice',
        options: Options(responseType: ResponseType.bytes),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$invoiceNum.pdf');
      await file.writeAsBytes(res.data!);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Invoice $invoiceNum — Rama Country Farm',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
