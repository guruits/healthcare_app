import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../controller/consultation.controller.dart';

class ScanReportCard extends StatefulWidget {
  const ScanReportCard({super.key});

  @override
  State<ScanReportCard> createState() => _ScanReportCardState();
}

class _ScanReportCardState extends State<ScanReportCard> {

  @override
  void initState() {
    super.initState();
    _loadMockPatientHistory();
  }

  void _loadMockPatientHistory(){
    _scanReports.add(
      ScanReport(
        id: 'XR-25042301',
        scanType: 'Chest X-Ray',
        team: 'Radiology',
        datePerformed: '2025-04-20',
        findings: 'Clear lung fields. No evidence of consolidation or effusion. Heart size within normal limits.',
        conclusion: 'Normal chest radiograph.',
        imageUrls: ['assets/images/appointments.png'],
      ),
    );
  }

  final List<MedicalHistory> _patientHistory = generateSampleMedicalHistory();
  final List<ScanReport> _scanReports = [];
  final ConsultationController _controller = ConsultationController();


  void _viewScanReports() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildScanReportsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Professional header with corporate styling
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A365D), // Navy blue header to match dialog
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.description, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Diagnostic Reports',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_scanReports.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.visibility, size: 18, color: Colors.white70),
                        label: const Text(
                          'View All',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: _viewScanReports,
                      ),
                  ],
                ),
              ),

              // Content area with proper padding
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Empty state with professional styling
                    if (_scanReports.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 48,
                              color: const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Diagnostic Reports Available',
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Completed scan requests will appear here',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to request scan screen or open dialog
                                //_buildScanRequestDialog();
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Request New Scan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A365D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                    // Professional reports list with improved styling
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _scanReports.length > 2 ? 2 : _scanReports.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final report = _scanReports[index];
                          return _buildReportItem(report, isSmallScreen);
                        },
                      ),

                    // "View more" button with counter - professional styling
                    if (_scanReports.length > 2) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: Text('View All ${_scanReports.length} Reports'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A365D),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: _viewScanReports,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportItem(ScanReport report, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showScanReportDetails(report),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Report Type and ID
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            size: 16,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.scanType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Report ID: ${report.id}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Only show badge on larger screens
                  if (!isSmallScreen)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: Color(0xFF0F766E),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified',
                            style: TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Report metadata in a professional format
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Two-column layout on larger screens
                    if (!isSmallScreen)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetadataItem(
                              Icons.calendar_today_outlined,
                              'Date Performed',
                              report.datePerformed,
                            ),
                          ),
                          Expanded(
                            child: _buildMetadataItem(
                              Icons.people_outline,
                              'Team',
                              report.team,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildMetadataItem(
                            Icons.calendar_today_outlined,
                            'Date Performed',
                            report.datePerformed,
                          ),
                          const SizedBox(height: 8),
                          _buildMetadataItem(
                            Icons.people_outline,
                            'Team',
                            report.team,
                          ),
                        ],
                      ),

                    const Divider(height: 24, thickness: 1),

                    // Conclusion section
                    const Text(
                      'Conclusion',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF334155),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        report.conclusion,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons with formal styling
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isSmallScreen)
                      TextButton.icon(
                        icon: const Icon(Icons.print_outlined, size: 16),
                        label: const Text('Print'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          // Print functionality would go here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Printing report...')),
                          );
                        },
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A365D),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () => _showScanReportDetails(report),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ],
    );
  }


  void _showScanReportDetails(ScanReport report) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        final theme = Theme.of(context);
        final screenSize = MediaQuery.of(context).size;
        final maxHeight = screenSize.height * 0.85;
        final maxWidth = screenSize.width * 0.92;

        // Define custom animation for dialog entry
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 16,
            clipBehavior: Clip.antiAlias,
            backgroundColor: theme.colorScheme.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: maxWidth,
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                maxWidth: maxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with modern, professional styling
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          Color.lerp(theme.colorScheme.primary, theme.colorScheme.secondary, 0.6)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getScanIcon(report.scanType),
                            color: theme.colorScheme.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.scanType,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onPrimary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ID: ${report.id}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: theme.colorScheme.onPrimary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Scan metadata banner
                  Container(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(report.datePerformed),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.group,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  report.team,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content in a scrollable area with improved visual hierarchy
                  Flexible(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // Findings section with improved styling
                              _buildReportSection(
                                context,
                                title: 'Findings',
                                icon: Icons.search,
                                content: report.findings,
                                backgroundColor: theme.colorScheme.surface,
                                borderColor: theme.colorScheme.outline.withOpacity(0.2),
                              ),

                              const SizedBox(height: 24),

                              // Conclusion section with visual emphasis
                              _buildReportSection(
                                context,
                                title: 'Conclusion',
                                icon: Icons.verified,
                                content: report.conclusion,
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                                borderColor: theme.colorScheme.primary.withOpacity(0.2),
                                textStyle: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                                ),
                              ),

                              if (report.imageUrls.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                _buildSectionTitle(context, 'Diagnostic Images', Icons.image),
                                const SizedBox(height: 12),
                                _buildImageGallery(context, report.imageUrls),
                              ],
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer with action buttons
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share'),
                          onPressed: () {
                            _showShareOptions(context, report);
                          },
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.print),
                              label: const Text('Print'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showPrintingSnackbar(context);
                              },
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Done'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPrintingSnackbar(BuildContext context) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(width: 16),
            const Text('Preparing report for printing...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'CANCEL',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }


  void _showShareOptions(BuildContext context, ScanReport report) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              'Share Report',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  context,
                  icon: Icons.email,
                  label: 'Email',
                  color: Colors.red.shade400,
                  onTap: () {
                    Navigator.pop(context);
                    // Implementation for email sharing
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.message,
                  label: 'Message',
                  color: Colors.green.shade400,
                  onTap: () {
                    Navigator.pop(context);
                    // Implementation for message sharing
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.folder,
                  label: 'Save',
                  color: Colors.blue.shade400,
                  onTap: () {
                    Navigator.pop(context);
                    // Implementation for saving
                  },
                ),
                _buildShareOption(
                  context,
                  icon: Icons.qr_code,
                  label: 'QR Code',
                  color: Colors.purple.shade400,
                  onTap: () {
                    Navigator.pop(context);
                    // Implementation for QR code sharing
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildImageGallery(BuildContext context, List<String> imageUrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return _buildEnhancedImageThumbnail(context, imageUrls[index]);
      },
    );
  }

  Widget _buildEnhancedImageThumbnail(BuildContext context, String imageUrl) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, imageUrl),
      child: Hero(
        tag: 'scan_image_$imageUrl',
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.errorContainer.withOpacity(0.2),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: theme.colorScheme.error,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image Unavailable',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Zoom indicator and type label
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _getImageTypeBadge(context, imageUrl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getImageTypeBadge(BuildContext context, String imageUrl) {
    final imageType = _getImageTypeFromUrl(imageUrl);
    Color badgeColor;

    if (imageType.contains('X-Ray')) {
      badgeColor = Colors.blue;
    } else if (imageType.contains('MRI')) {
      badgeColor = Colors.purple;
    } else if (imageType.contains('CT')) {
      badgeColor = Colors.green;
    } else {
      badgeColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        imageType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getImageTypeFromUrl(String imageUrl) {
    // This is a placeholder - in a real app, you would examine the URL or metadata
    // to determine the image type
    final url = imageUrl.toLowerCase();

    if (url.contains('xray') || url.contains('x-ray')) {
      return 'X-Ray';
    } else if (url.contains('mri')) {
      return 'MRI';
    } else if (url.contains('ct')) {
      return 'CT Scan';
    } else if (url.contains('ultrasound')) {
      return 'Ultrasound';
    } else {
      return 'Image';
    }
  }


  void _showFullScreenImage(BuildContext context, String imageUrl) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with interactive viewer for zoom/pan
            Hero(
              tag: 'scan_image_$imageUrl',
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Top app bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getImageTypeFromUrl(imageUrl),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {
                            // Implementation for sharing image
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Sharing image...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: () {
                            // Implementation for downloading image
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Image saved to gallery'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls for image manipulation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageControlButton(
                      icon: Icons.brightness_6,
                      label: 'Brightness',
                      onPressed: () {
                        // Implementation for brightness adjustment
                      },
                    ),
                    _buildImageControlButton(
                      icon: Icons.contrast,
                      label: 'Contrast',
                      onPressed: () {
                        // Implementation for contrast adjustment
                      },
                    ),
                    _buildImageControlButton(
                      icon: Icons.rotate_90_degrees_ccw,
                      label: 'Rotate',
                      onPressed: () {
                        // Implementation for rotation
                      },
                    ),
                    _buildImageControlButton(
                      icon: Icons.straighten,
                      label: 'Measure',
                      onPressed: () {
                        // Implementation for measurement tools
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildImageControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildReportSection(
      BuildContext context, {
        required String title,
        required IconData icon,
        required String content,
        required Color backgroundColor,
        required Color borderColor,
        TextStyle? textStyle,
      }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, title, icon),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            content,
            style: textStyle ?? theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }


  String _formatDate(String date) {
    // Implement date formatting logic based on your date string format
    // This is a placeholder assuming the date is already formatted
    return date;
  }


  IconData _getScanIcon(String scanType) {
    final lowercaseScanType = scanType.toLowerCase();

    if (lowercaseScanType.contains('xray') || lowercaseScanType.contains('x-ray')) {
      return Icons.broken_image;
    } else if (lowercaseScanType.contains('mri')) {
      return Icons.view_in_ar;
    } else if (lowercaseScanType.contains('ct') || lowercaseScanType.contains('cat')) {
      return Icons.view_comfy_alt;
    } else if (lowercaseScanType.contains('ultrasound')) {
      return Icons.waves;
    } else {
      return Icons.image_search;
    }
  }

  Widget _buildScanReportsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _scanReports.isEmpty
                    ? const Center(
                  child: Text(
                    'No scan reports available',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: _scanReports.length,
                  itemBuilder: (context, index) {
                    final report = _scanReports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          _showScanReportDetails(report);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getScanTypeIcon(report.scanType),
                                      color: Colors.purple,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          report.scanType,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text('ID: ${report.id}',
                                            style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        report.datePerformed,
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                      Text(
                                        report.team,
                                        style: TextStyle(
                                          color: Colors.purple[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Conclusion: ${report.conclusion}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (report.imageUrls.isNotEmpty) ...[
                                const Text('Images:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 70,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: report.imageUrls.length,
                                    itemBuilder: (context, imgIndex) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Container(
                                          width: 70,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.asset(
                                              report.imageUrls[imgIndex],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientHistorySheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet handle for better UX
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Medical History',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        _controller.patientName ?? 'unknown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              Expanded(
                child: _patientHistory.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No medical history available',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Medical records will appear here once added',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
                    : AnimatedList(
                  controller: scrollController,
                  initialItemCount: _patientHistory.length,
                  itemBuilder: (context, index, animation) {
                    final history = _patientHistory[index];
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: _buildHistoryCard(context, history),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getDiagnosisColor(String diagnosis) {
    final lowercaseDiagnosis = diagnosis.toLowerCase();

    if (lowercaseDiagnosis.contains('heart') || lowercaseDiagnosis.contains('cardiac')) {
      return Colors.red.shade700;
    } else if (lowercaseDiagnosis.contains('fracture') || lowercaseDiagnosis.contains('bone')) {
      return Colors.amber.shade800;
    } else if (lowercaseDiagnosis.contains('respiratory') || lowercaseDiagnosis.contains('lung')) {
      return Colors.blue.shade700;
    } else if (lowercaseDiagnosis.contains('diabetes') || lowercaseDiagnosis.contains('blood')) {
      return Colors.purple.shade700;
    } else if (lowercaseDiagnosis.contains('mental') || lowercaseDiagnosis.contains('depression')) {
      return Colors.teal.shade700;
    } else {
      return Colors.indigo.shade700;
    }
  }


  Widget _buildHistoryCard(BuildContext context, MedicalHistory history) {
    final theme = Theme.of(context);
    final accentColor = _getDiagnosisColor(history.diagnosis);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          backgroundColor: theme.colorScheme.surface,
          collapsedBackgroundColor: theme.colorScheme.surface,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getDiagnosisIcon(history.diagnosis),
              color: accentColor,
              size: 22,
            ),
          ),
          title: Text(
            _formatDate(history.date),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${history.doctorName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                history.diagnosis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 32),

            if (history.notes.isNotEmpty) ...[
              _buildSectionHeader(context, 'Clinical Notes', Icons.notes),
              const SizedBox(height: 12),
              ...history.notes.map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        note,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
            ],

            if (history.prescriptions.isNotEmpty) ...[
              _buildSectionHeader(context, 'Medications', Icons.medication),
              const SizedBox(height: 12),
              ...history.prescriptions.map((med) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.orange.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medication_liquid,
                            size: 18,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              med.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${med.dosage} - ${med.frequency}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Duration: ${med.duration}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (med.instructions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          med.instructions,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 20),
            ],

            if (history.scans.isNotEmpty) ...[
              _buildSectionHeader(context, 'Diagnostic Imaging', Icons.image_search),
              const SizedBox(height: 12),
              ...history.scans.map((scan) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.purple.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.purple.shade200,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showScanReportDetails(scan),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getScanIcon(scan!.scanType),
                            color: Colors.purple.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scan.scanType,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Performed: ${_formatDate(scan.datePerformed)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.purple.shade100,
                            foregroundColor: Colors.purple.shade800,
                          ),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('View'),
                          onPressed: () => _showScanReportDetails(scan),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
  IconData _getDiagnosisIcon(String diagnosis) {
    final lowercaseDiagnosis = diagnosis.toLowerCase();

    if (lowercaseDiagnosis.contains('heart') || lowercaseDiagnosis.contains('cardiac')) {
      return Icons.favorite;
    } else if (lowercaseDiagnosis.contains('fracture') || lowercaseDiagnosis.contains('bone')) {
      return Icons.healing;
    } else if (lowercaseDiagnosis.contains('respiratory') || lowercaseDiagnosis.contains('lung')) {
      return Icons.air;
    } else if (lowercaseDiagnosis.contains('diabetes') || lowercaseDiagnosis.contains('blood')) {
      return Icons.bloodtype;
    } else if (lowercaseDiagnosis.contains('mental') || lowercaseDiagnosis.contains('depression')) {
      return Icons.psychology;
    } else {
      return Icons.medical_services;
    }
  }

  IconData _getScanTypeIcon(String scanType) {
    scanType = scanType.toLowerCase();
    if (scanType.contains('x-ray') || scanType.contains('xray')) {
      return Icons.image;
    } else if (scanType.contains('mri')) {
      return Icons.panorama;
    } else if (scanType.contains('ct') || scanType.contains('cat')) {
      return Icons.view_in_ar;
    } else if (scanType.contains('blood') || scanType.contains('lab')) {
      return Icons.science;
    } else if (scanType.contains('ecg') || scanType.contains('ekg') || scanType.contains('cardio')) {
      return Icons.monitor_heart;
    } else {
      return Icons.description;
    }
  }
}

class MedicalHistory {
  final String date;
  final String doctorName;
  final String diagnosis;
  final List<String> notes;
  final List<Prescriptionc> prescriptions;
  final List<ScanReport> scans;

  MedicalHistory({
    required this.date,
    required this.doctorName,
    required this.diagnosis,
    required this.notes,
    required this.prescriptions,
    required this.scans,
  });
}

class Prescriptionc {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  Prescriptionc({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions = '',
  });
}

List<MedicalHistory> generateSampleMedicalHistory() {
  return [
    MedicalHistory(
      date: '2025-04-10',
      doctorName: 'Dr. Sarah Johnson',
      diagnosis: 'Hypertension',
      notes: [
        'Blood pressure readings consistently above 140/90 mmHg',
        'Patient reports occasional headaches and dizziness',
        'Family history of cardiovascular disease',
        'Recommended lifestyle modifications including reduced sodium intake and regular exercise'
      ],
      prescriptions: [
        Prescriptionc(
          name: 'Lisinopril',
          dosage: '10mg',
          frequency: 'Once daily',
          duration: '3 months',
          instructions: 'Take in the morning with water',
        ),
        Prescriptionc(
          name: 'Hydrochlorothiazide',
          dosage: '12.5mg',
          frequency: 'Once daily',
          duration: '3 months',
          instructions: 'Take with food to minimize stomach upset',
        ),
      ],
      scans: [
        ScanReport(
          id: 'ECG-2025-0412',
          scanType: 'Electrocardiogram',
          team: 'Cardiology Department',
          datePerformed: '2025-04-10',
          findings: 'Normal sinus rhythm. Heart rate 76 bpm. Normal QRS complex and ST segments. No significant abnormalities detected.',
          conclusion: 'Normal ECG findings. No evidence of ischemia or arrhythmia at this time.',
          imageUrls: [
            'https://example.com/images/ecg-1.jpg',
            'https://example.com/images/ecg-2.jpg',
          ],
        ),
      ],
    ),
    MedicalHistory(
      date: '2025-03-15',
      doctorName: 'Dr. Michael Chen',
      diagnosis: 'Acute Bronchitis',
      notes: [
        'Patient presents with productive cough for 5 days',
        'Low-grade fever (99.8°F)',
        'Chest auscultation reveals scattered rhonchi and wheezing',
        'No signs of pneumonia on examination'
      ],
      prescriptions: [
        Prescriptionc(
          name: 'Azithromycin',
          dosage: '500mg',
          frequency: 'Once daily',
          duration: '5 days',
          instructions: 'Take 2 hours before or after antacids',
        ),
        Prescriptionc(
          name: 'Benzonatate',
          dosage: '200mg',
          frequency: 'Three times daily',
          duration: '7 days',
          instructions: 'Swallow capsules whole, do not chew',
        ),
      ],
      scans: [
        ScanReport(
          id: 'CXR-2025-0315',
          scanType: 'Chest X-Ray',
          team: 'Radiology',
          datePerformed: '2025-03-15',
          findings: 'Mild peribronchial thickening. No consolidation, effusion, or pneumothorax. Heart size within normal limits. No cardiomegaly observed.',
          conclusion: 'Findings consistent with bronchitis. No evidence of pneumonia or other significant pulmonary disease.',
          imageUrls: [
            'https://example.com/images/chest-xray-1.jpg',
            'https://example.com/images/chest-xray-2.jpg',
          ],
        ),
      ],
    ),
    MedicalHistory(
      date: '2025-02-02',
      doctorName: 'Dr. Emily Wilson',
      diagnosis: 'Lumbar Strain',
      notes: [
        'Patient reports lower back pain after lifting heavy furniture',
        'Pain increases with movement, particularly bending and twisting',
        'No radicular symptoms or neurological deficits',
        'Negative straight leg raise test'
      ],
      prescriptions: [
        Prescriptionc(
          name: 'Naproxen',
          dosage: '500mg',
          frequency: 'Twice daily',
          duration: '10 days',
          instructions: 'Take with food',
        ),
        Prescriptionc(
          name: 'Cyclobenzaprine',
          dosage: '10mg',
          frequency: 'Three times daily',
          duration: '7 days',
          instructions: 'May cause drowsiness. Avoid alcohol.',
        ),
      ],
      scans: [
        ScanReport(
          id: 'MRI-2025-0203',
          scanType: 'MRI Lumbar Spine',
          team: 'Neurology Imaging',
          datePerformed: '2025-02-03',
          findings: 'Mild degenerative changes at L4-L5 and L5-S1 levels. No significant disc herniation or spinal stenosis. Paraspinal muscles show mild inflammation consistent with strain. No evidence of fracture or misalignment.',
          conclusion: 'Findings consistent with mild lumbar strain. Degenerative changes appropriate for patient age. No surgical lesions identified.',
          imageUrls: [
            'https://example.com/images/mri-lumbar-1.jpg',
            'https://example.com/images/mri-lumbar-2.jpg',
            'https://example.com/images/mri-lumbar-3.jpg',
          ],
        ),
      ],
    ),
    MedicalHistory(
      date: '2024-12-18',
      doctorName: 'Dr. Robert Taylor',
      diagnosis: 'Type 2 Diabetes Mellitus - Routine Follow-up',
      notes: [
        'HbA1c improved to 6.8% from 7.5% at previous visit',
        'Patient reports compliance with medication and dietary changes',
        'No symptoms of hypoglycemia',
        'Weight loss of 3.5kg since last visit'
      ],
      prescriptions: [
        Prescriptionc(
          name: 'Metformin',
          dosage: '1000mg',
          frequency: 'Twice daily',
          duration: '3 months',
          instructions: 'Take with meals',
        ),
        Prescriptionc(
          name: 'Empagliflozin',
          dosage: '10mg',
          frequency: 'Once daily',
          duration: '3 months',
          instructions: 'Take in the morning with or without food',
        ),
      ],
      scans: [],
    ),
  ];
}
class ScanReport {
  final String id;
  final String scanType;
  final String team;
  final String datePerformed;
  final String findings;
  final String conclusion;
  final List<String> imageUrls; // URLs to scan images

  ScanReport({
    required this.id,
    required this.scanType,
    required this.team,
    required this.datePerformed,
    required this.findings,
    required this.conclusion,
    this.imageUrls = const [],
  });
}
