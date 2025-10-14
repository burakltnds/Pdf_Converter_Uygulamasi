import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_saver/file_saver.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final String backendUrl =
      kIsWeb ?  "http://localhost:5000/convert"
      :"http://10.29.175.196:5000/convert";

  String _mesaj = "PDF dosyanızı Seçiniz" ;
  bool _isLoading = false ;

  Future <void> pickAndConvert () async {
    // pdf dosyasını seçtiğimiz yer
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom ,
        allowedExtensions: ["pdf"]
    );

    if (result != null) {
      File pdfFile = File(result.files.single.path!);
      setState(()
      {
        _isLoading = true;
        _mesaj = "Dosya Yükleniyor";
      });

      try {
        // 2 dosyayı python sunucusuna gönderir
        var request = http.MultipartRequest("POST" , Uri.parse(backendUrl));
        if (kIsWeb){
          request.files.add(
            http.MultipartFile.fromBytes(
                "file",
                result.files.first.bytes!,
                filename: result.files.first.name));
        }else{
        request.files.add(
          await http.MultipartFile.fromPath("file", pdfFile.path),
        );}

        var streamedResponse = await request.send();


        // 3. gelen yanıtı işleme kısmı

        if (streamedResponse.statusCode == 200){
          var responseBytes = await streamedResponse.stream.toBytes();

          if(kIsWeb){
            String outputFileNameWithExt = result.files.single.name.endsWith(".pdf")
                ? result.files.single.name.replaceAll(".pdf", ".docx")
                : "${result.files.single.name}.docx" ;
            final blob = html.Blob([responseBytes] , "application/vnd.openxmlformats-officedocument.wordprocessingml.document");
            final url = html.Url.createObjectUrlFromBlob(blob);
            final anchor = html.AnchorElement(href:url)
            ..setAttribute("download", outputFileNameWithExt)
            ..click();
            html.Url.revokeObjectUrl(url);
            setState(() {
              _mesaj = "Dönüştürme Başarılı Dosya İndiriliyor";
            });
          }else {
            String originalFileName = result.files.single.name;
            String outputFileName = originalFileName.endsWith(".pdf")
                ? originalFileName.replaceAll(".pdf", "")
                : originalFileName;

            String? savedPath = await FileSaver.instance.saveAs(
                name: outputFileName,
                bytes: responseBytes,
                mimeType: MimeType.microsoftWord,
                ext: "docx"
            );

            setState(() {
              _mesaj = savedPath != null
                  ? "Dosya Başarıyla Kaydedildi: $savedPath"
                  : "Kaydetme İşlemi Kullanıcı Tarafından İptal Edildi";
            });
          }
        }else {
          final responseBody = await streamedResponse.stream.bytesToString();
          setState(() {
            _mesaj = "HATA: ${streamedResponse.statusCode}\nSunucu yanıtı: $responseBody";
          });
        }

        }catch (e) {
        setState(() {
          _isLoading = false;
          _mesaj = "Bağlantı Hatası: $e" ;
        });
       }finally {
        setState(() {
          _isLoading = false;
        });
      }
        }else {
         setState(() {
        _mesaj = "Dosya Seçilmedi...";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.transform , size :80 , color: Colors.blueAccent) ,
              const SizedBox(height: 24),
              Text(_mesaj , textAlign: TextAlign.center , style: const TextStyle(fontSize: 16),),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
              ElevatedButton(
                  onPressed: pickAndConvert,
                  child: const Text("PDF Seç")
              )
            ],
          ) ,
        
        ),
      ),
    );
  }
}



