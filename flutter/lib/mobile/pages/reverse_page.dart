import 'package:flutter/material.dart';

import '../../common.dart';
import '../../models/platform_model.dart';
import 'remote_page.dart';

class ReversePage extends StatefulWidget {
  ReversePage({
    Key? key,
    required this.port,
    this.pinnedPk = '',
  }) : super(key: key);

  final int port;
  final String pinnedPk;

  @override
  State<ReversePage> createState() => _ReversePageState();
}

class _ReversePageState extends State<ReversePage> {
  late final TextEditingController _pinController =
      TextEditingController(text: widget.pinnedPk);
  late final TextEditingController _portController =
      TextEditingController(text: widget.port > 0 ? '${widget.port}' : '23456');
  final _passwordController = TextEditingController();
  bool _waiting = false;
  String? _peerId;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.pinnedPk.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final pin = _pinController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 0;
    if (pin.isEmpty) {
      setState(() => _error = '请输入 PC 公钥（base64）');
      return;
    }
    if (port <= 0 || port > 65535) {
      setState(() => _error = '端口无效');
      return;
    }
    setState(() {
      _waiting = true;
      _error = null;
    });
    try {
      final id = await bind.mainReverseListen(port: port, pinnedPk: pin);
      if (!mounted) return;
      setState(() {
        _peerId = id;
        _waiting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _waiting = false;
        _error = '$e';
      });
    }
  }

  void _open(bool viewOnly) {
    final id = _peerId;
    if (id == null) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => RemotePage(
        id: id,
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
        viewOnly: viewOnly,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(translate('Reverse connection'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: 'PC public key (base64)',
                border: const OutlineInputBorder(),
                hintText: '从 PC 的 id_ed25519.pub 读出的 Ed25519 公钥',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Listen port',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PC password (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_peerId == null) ...[
              ElevatedButton(
                onPressed: _waiting ? null : _start,
                child: _waiting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('等待 PC 反向连接...'),
                          ],
                        ),
                      )
                    : const Text('开始监听'),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('PC 已在线'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('PC ID: $_peerId'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _open(true),
                      child: const Text('仅查看'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _open(false),
                      child: const Text('远程控制'),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}