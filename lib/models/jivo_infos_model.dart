import 'package:flutter/material.dart';

class JivoInfos {
  JivoInfos({
    required this.websiteId,
    required this.referenceUrl,
    this.loading,
  });

  final String websiteId;
  final String referenceUrl;

  Widget? loading;

  void setLoading(Widget widget) {
    loading = widget;
  }
}
