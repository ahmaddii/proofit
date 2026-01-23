import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/proof_model.dart';
import '../services/location_service.dart';

class PdfService {
  final LocationService _locationService = LocationService();

  Future<void> generateAndShareProofPdf({
    required ProofModel proof,
    Map<String, Uint8List>? decryptedMedia,
    String? decryptedText,
    String? cityName,
  }) async {
    try {
      final pdf = pw.Document();

      // Add content to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader(proof),
              pw.SizedBox(height: 20),
              
              // Title
              pw.Text(
                proof.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              // Timestamp
              _buildTimestamp(proof),
              pw.SizedBox(height: 20),
              
              // Locked Status
              if (proof.lockedFlag) _buildLockedStatus(),
              pw.SizedBox(height: 20),
              
              // Description
              _buildDescription(proof),
              pw.SizedBox(height: 20),
              
              // Location
              if (proof.latitude != null && proof.longitude != null)
                _buildLocation(proof, cityName),
              if (proof.latitude != null && proof.longitude != null)
                pw.SizedBox(height: 20),
              
              // Media Images
              if (decryptedMedia != null && decryptedMedia.isNotEmpty)
                _buildMediaSection(decryptedMedia),
              if (decryptedMedia != null && decryptedMedia.isNotEmpty)
                pw.SizedBox(height: 20),
              
              // Text Content
              if (decryptedText != null && decryptedText.isNotEmpty)
                _buildTextContent(decryptedText),
              if (decryptedText != null && decryptedText.isNotEmpty)
                pw.SizedBox(height: 20),
              
              // Content Hash
              _buildContentHash(proof),
              pw.SizedBox(height: 20),
              
              // Footer
              _buildFooter(proof),
            ];
          },
        ),
      );

      // Share/Print PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  pw.Widget _buildHeader(ProofModel proof) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'ProofIt - Evidence Document',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'ID: ${proof.proofId.substring(0, 8)}...',
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildTimestamp(ProofModel proof) {
    final dateFormat = DateFormat('MMMM dd, yyyy • hh:mm:ss a');
    return pw.Row(
      children: [
        pw.Text(
          'Created: ${dateFormat.format(proof.timestamp)}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildLockedStatus() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.green100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            '🔒 This proof is locked and cannot be modified',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDescription(ProofModel proof) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Description',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            proof.description ?? 'No description provided',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildLocation(ProofModel proof, String? cityName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Location',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            cityName ?? 
            _locationService.formatLocation(proof.latitude, proof.longitude),
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMediaSection(Map<String, Uint8List> decryptedMedia) {
    final images = <pw.Widget>[];
    
    decryptedMedia.forEach((key, imageBytes) {
      try {
        final image = pw.MemoryImage(imageBytes);
        images.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Evidence Image ${key.split('_').last}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Image(
                    image,
                    fit: pw.BoxFit.contain,
                    width: 500,
                    height: 400,
                  ),
                ),
              ],
            ),
          ),
        );
      } catch (e) {
        // Skip images that can't be loaded
        print('Error loading image for PDF: $e');
      }
    });

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Media Evidence (${decryptedMedia.length} ${decryptedMedia.length == 1 ? 'image' : 'images'})',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...images,
        ],
      ),
    );
  }

  pw.Widget _buildTextContent(String decryptedText) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Text Evidence',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            decryptedText,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildContentHash(ProofModel proof) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Content Hash (Tamper Detection)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This hash verifies the integrity of this proof. Any modification to the content will change this hash.',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              proof.contentHash,
              style: const pw.TextStyle(
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(ProofModel proof) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Generated on ${dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'ProofIt - Secure Evidence Management',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
