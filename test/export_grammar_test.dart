import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:topik_go/features/grammar/data/korean_grammar_dataset.dart';

void main() {
  test('Export master grammar dataset to JSON for server seeding', () {
    final jsonList = kMasterGrammarList.map((g) => g.toJson()).toList();
    final out = File('/Users/husanboyhakimov/Documents/OtherDevProjects/TopikGo/topik-server/prisma/seed/master-grammar-dataset.json');
    out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonList));
    expect(jsonList.length, greaterThanOrEqualTo(25));
  });
}
