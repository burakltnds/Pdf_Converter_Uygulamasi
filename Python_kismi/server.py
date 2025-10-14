from flask import Flask , request , send_file , jsonify , after_this_request
from werkzeug.utils import secure_filename
import ana
import os
from flask_cors import CORS

# FLASK Kısmı
app = Flask(__name__)
CORS(app)

#Dosyaların Geçici Yükleneceği klasorler
UPLOAD_FOLDER = "uploads"
OUTPUT_FOLDER = "outputs"

os.makedirs(UPLOAD_FOLDER , exist_ok=True)
os.makedirs(OUTPUT_FOLDER , exist_ok=True)

# API endpoint : flutter bu adrese istek gönderir
@app.route('/convert' , methods=['POST'])
def convert_pdf():
    #1.Gelen isteği kontrol et
    if 'file' not in request.files:
        return jsonify({"error" : "İstekte dosya bulunamadı"}) , 400
    
    file = request.files['file']

    #2.Dosya adı boş mu veya dosya türü pdf değil mi
    if file.filename == "":
        return jsonify ({"error":"Dosya Seçilmedi"}) , 400
    
    if not file.filename.lower().endswith('.pdf'):
        return jsonify ({"error":"Lütfen bir PDF dosyası seçiniz."}) , 400

    # dosya adını temizleme
    filename = secure_filename(file.filename)

    #dosya kayıt yolunu belirle

    pdf_path = os.path.join (UPLOAD_FOLDER , filename)

    output_filename = os.path.splitext(filename)[0] + ".docx"
    output_path = os.path.join(OUTPUT_FOLDER, output_filename)
    
    pdf_path_exists = os.path.exists(pdf_path)
    output_path_exists = os.path.exists (output_path)

    try:
        #3.flutterdan gelen dosyaları sunucuya kaydet
        file.save(pdf_path)
        pdf_path_exists = True

        #4.fonksiyonları çağır
        print(f"{filename} okunuyor...")
        text = ana.metni_cikar(pdf_path)

        print("metin temizleniyor")
        cleaned_lines = ana.clean_text(text)

        print(f"Word dosyası ({output_filename}) kaydediliyor...")
        ana.save_to_word (cleaned_lines , output_path)
        output_path_exists = True
        #4.5 çöpleri temizle
        @after_this_request
        def cleanup(response):
            try:
                if os.path.exists(pdf_path):
                    os.remove(pdf_path)
                if os.path.exists(output_path):
                    os.remove(output_path)
                print("Geçici Dosyalar Silindi")
            except PermissionError:
                print(f"🧼 Uyarı: Dosyalar hala kullanımda olduğu için silinemedi. Bu normal bir durum olabilir.")
            except Exception as e:
                print(f"🧼 Temizlik sırasında beklenmedik bir hata oluştu: {e}")
            return response
         

        #5.oluşturulan word dosyasını fluttera geri gönder
        print("Dosya geri gönderiliyor")

        return send_file (
            output_path ,
            as_attachment=True ,
            download_name=output_filename
        )

    except Exception as e:
        if os.path.exists(pdf_path):
            os.remove(pdf_path)
        print(f"HATA: {str(e)}")
        return jsonify ({"error" : f"Dönüştürme sırasında bir hata oluştu: {str(e)}"}) , 500

if __name__ == '__main__':
    app.run(host='0.0.0.0' , port=5000 , debug=True)