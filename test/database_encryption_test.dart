import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('migrates a plaintext database and requires the correct key', () async {
    final directory = await Directory.systemTemp.createTemp(
      'tinkiyagro_cipher',
    );
    final file = File('${directory.path}/offline.sqlite');
    const key = '74696e6b69796167726f2d746573742d6b6579';

    final plaintext = sqlite3.open(file.path);
    plaintext.execute('CREATE TABLE secret (value TEXT NOT NULL)');
    plaintext.execute("INSERT INTO secret VALUES ('pedido privado')");
    plaintext.execute("PRAGMA cipher = 'sqlcipher'");
    plaintext.execute("PRAGMA hexrekey = '$key'");
    plaintext.close();

    final header = await file
        .openRead(0, 16)
        .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
    expect(String.fromCharCodes(header), isNot('SQLite format 3\u0000'));

    final wrongKey = sqlite3.open(file.path);
    wrongKey.execute("PRAGMA cipher = 'sqlcipher'");
    wrongKey.execute("PRAGMA hexkey = '00'");
    expect(() => wrongKey.select('SELECT * FROM secret'), throwsA(anything));
    wrongKey.close();

    final encrypted = sqlite3.open(file.path);
    encrypted.execute("PRAGMA cipher = 'sqlcipher'");
    encrypted.execute("PRAGMA hexkey = '$key'");
    expect(
      encrypted.select('SELECT value FROM secret').single['value'],
      'pedido privado',
    );
    encrypted.close();

    await directory.delete(recursive: true);
  });
}
