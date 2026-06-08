import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/import_service.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Library'),
      ),
      body: Consumer<ImportService>(
        builder: (context, importService, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildContent(context, importService),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ImportService importService) {
    switch (importService.status) {
      case ImportStatus.idle:
        return _buildIdleState(context, importService);
      case ImportStatus.importing:
        return _buildImportingState(importService);
      case ImportStatus.completed:
        return _buildCompletedState(context, importService);
      case ImportStatus.failed:
        return _buildFailedState(context, importService);
      case ImportStatus.cancelled:
        return _buildCancelledState(context, importService);
    }
  }

  Widget _buildIdleState(BuildContext context, ImportService importService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_download, size: 80, color: Color(0xFF1DB954)),
          const SizedBox(height: 24),
          const Text(
            'Import Your Spotify Library',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'This will import your liked songs and playlists '
            'so you can start tagging and querying your music.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => importService.importLibrary(),
            icon: const Icon(Icons.download),
            label: const Text('Start Import'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportingState(ImportService importService) {
    final progress = importService.progress;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 32),
          Text(
            progress.currentStep,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (progress.totalSongs > 0) ...[
            _buildProgressRow(
              'Songs',
              progress.importedSongs,
              progress.totalSongs,
              progress.songProgress,
            ),
            const SizedBox(height: 12),
          ],
          if (progress.totalPlaylists > 0) ...[
            _buildProgressRow(
              'Playlists',
              progress.importedPlaylists,
              progress.totalPlaylists,
              progress.playlistProgress,
            ),
            const SizedBox(height: 12),
          ],
          if (progress.overallProgress > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.overallProgress),
            const SizedBox(height: 8),
            Text(
              '${(progress.overallProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => importService.cancelImport(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
      String label, int current, int total, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$current / $total'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: progress),
      ],
    );
  }

  Widget _buildCompletedState(
      BuildContext context, ImportService importService) {
    final progress = importService.progress;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Color(0xFF1DB954)),
          const SizedBox(height: 24),
          const Text(
            'Import Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Imported ${progress.importedSongs} songs from '
            '${progress.importedPlaylists} playlists',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              importService.reset();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedState(BuildContext context, ImportService importService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 24),
          const Text(
            'Import Failed',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            importService.errorMessage ?? 'An unknown error occurred',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => importService.importLibrary(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              importService.reset();
              Navigator.of(context).pop();
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledState(
      BuildContext context, ImportService importService) {
    final progress = importService.progress;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel_outlined, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          const Text(
            'Import Cancelled',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Partially imported ${progress.importedSongs} songs and '
            '${progress.importedPlaylists} playlists',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => importService.importLibrary(),
            icon: const Icon(Icons.refresh),
            label: const Text('Restart Import'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              importService.reset();
              Navigator.of(context).pop();
            },
            child: const Text('Keep Partial Import'),
          ),
        ],
      ),
    );
  }
}
