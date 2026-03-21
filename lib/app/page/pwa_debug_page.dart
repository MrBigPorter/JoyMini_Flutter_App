import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/utils/pwa_helper.dart';

class PwaDebugPage extends StatefulWidget {
  const PwaDebugPage({super.key});

  @override
  State<PwaDebugPage> createState() => _PwaDebugPageState();
}

class _PwaDebugPageState extends State<PwaDebugPage> {
  bool _updateAvailable = false;
  bool _installedPwa = false;
  bool _checking = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _syncState();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _syncState());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  void _syncState() {
    if (!mounted) return;
    setState(() {
      _updateAvailable = PwaHelper.updateAvailable;
      _installedPwa = PwaHelper.isInstalledPwa;
    });
  }

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    await PwaHelper.checkForUpdate();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _syncState();
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'PWA Debug',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Platform'),
              subtitle: Text(kIsWeb ? 'Web' : 'Non-Web'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Installed PWA'),
              subtitle: Text(_installedPwa ? 'Yes' : 'No'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Update Available'),
              subtitle: Text(_updateAvailable ? 'Yes (waiting worker)' : 'No'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _checking ? null : _checkUpdate,
            icon: _checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: const Text('Check for SW Update'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _updateAvailable ? PwaHelper.applyUpdate : null,
            icon: const Icon(Icons.system_update),
            label: const Text('Apply Update Now'),
          ),
        ],
      ),
    );
  }
}
