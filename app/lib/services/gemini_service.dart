import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../types/bill.dart';

class GeminiService {
  late final GenerativeModel _model;
  
  // Hardcoded key from 9_run.MD as requested
  // In production, this should be in .env or compile-time config
  static const String _apiKey = 'AIzaSyDtdsEhhGNZaO-5qw5ZnjO56PtiGH3FCvY';

  final String _modelName = 'gemini-flash-lite-latest';

  GeminiService() {
    print('Configuration: Model=$_modelName, Key=${_apiKey.isNotEmpty ? "Loaded (Starts with ${_apiKey.substring(0,4)}...)" : "Missing"}');
    _model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _billSchema,
      ),
      systemInstruction: Content.system(
          '你是一個專業的財務助手，專精於 OCR 與帳單辨識，特別是台灣地區的帳單。請精準判讀日期與數字。所有貨幣請回傳 ISO 代碼或符號 (例如 NT\$)。請使用繁體中文。'),
    );
  }

  static final Schema _billSchema = Schema.object(properties: {
    'title': Schema.string(description: "帳單來源或服務商名稱 (例如：台灣電力公司、中華電信)。請使用繁體中文。"),
    'amount': Schema.number(description: "總繳費金額。"),
    'currency': Schema.string(description: "幣別符號 (例如：NT\$, USD)。如果是台幣請回傳 'NT\$'。"),
    'dueDate': Schema.string(description: "繳費期限，格式為 YYYY-MM-DD。"),
    'note': Schema.string(description: "繳費期限區間或備註。格式請用：YYYY-MM-DD 至 YYYY-MM-DD。若無明確區間，可留空或填寫其他重要備註。"),
    'category': Schema.string(description: "帳單類別 (例如：水電費、電信費、信用卡)。請使用繁體中文。"),
    'recurrence': Schema.number(description: "週期性帳單偵測：0=不重複, 1=每月, 2=每年 (Detect keywords like 'Monthly', 'Annual', 'Subscription')"),
  }, requiredProperties: [
    'title',
    'amount',
    'dueDate'
  ]);

  Future<Bill?> extractBillFromImage(File imageFile) async {
    print("--- Start Gemini Image Analysis ---");
    try {
      final imageBytes = await imageFile.readAsBytes();
      print("Image Size: ${imageBytes.length} bytes");
      
      final prompt = Content.multi([
        TextPart(
            """
            分析這張圖片，這是一張帳單、繳費通知或訂閱證明(如 Spotify, Netflix, YouTube Premium)。
            
            請擷取以下資訊並回傳 JSON：
            1. **title**: 服務商名稱 (如 Spotify, YouTube Premium, 中華電信)。
            2. **amount**: 總金額。
            3. **currency**: 幣別 (如 NT\$, TRY)。
            4. **dueDate**: 繳費期限或扣款日期 (YYYY-MM-DD)。
               - 若是訂閱制，請找「下次帳單日期」、「續約日期」或「扣款日」。
            5. **recurrence**: 週期性偵測 (0=無, 1=每月, 2=每年)。
               - 關鍵字偵測：
                 - 每月: "月費", "每月", "/月", "/mo", "Monthly", "Automatic renewal", "自動續訂".
                 - 每年: "年費", "每年", "/年", "/yr", "Yearly", "Annual".
            6. **note**: 備註 (如「個人方案」、「家庭方案」或繳費區間)。
            7. **category**: 類別 (如 訂閱服務, 電信費)。

            請使用繁體中文。
            """),
        DataPart('image/jpeg', imageBytes),
      ]);

      print("Sending request to Gemini ($_modelName)...");
      final response = await _model.generateContent([prompt]);
      print("Gemini Response Recieved.");
      
      if (response.text != null) {
        return _parseBill(response.text!);
      }
      print("Gemini Response is Empty.");
      return null;
    } catch (e, stack) {
      print('!!! Gemini Error Occurred !!!');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      if (e is GenerativeAIException) {
         print('GenerativeAIException Details: ${e.message}');
      }
      print('Stack Trace: $stack');
      throw e;
    }
  }

  Future<Bill?> extractBillFromText(String text) async {
    print("--- Start Gemini Text Analysis ---");
    print("Input Text Length: ${text.length}");
    try {
      final prompt = Content.text(
          """
          請分析以下帳單/訂閱文字內容，回傳 JSON。

          **週期性偵測規則 (recurrence)**：
          - **1 (每月)**: 出現 "月費", "每月", "每個月", "/月", "mo", "month", "自動續訂" 等字眼。
          - **2 (每年)**: 出現 "年費", "每年", "/年", "yr", "year", "Annual" 等字眼。
          - **0 (無)**: 一般單次繳費帳單。

          **欄位說明**：
          - title: 服務名稱 (如 Spotify, Netflix, 電信費)
          - amount: 金額 (數值)
          - currency: 幣別 (預設 NT\$)
          - dueDate: 期限/扣款日 (YYYY-MM-DD)
          - note: 備註 (方案名稱、區間)
          - category: 類別 (訂閱服務, 生活繳費...)
          - recurrence: 0, 1, or 2

          文字內容：
          "$text"
          
          請使用繁體中文。
          """);

      print("Sending request to Gemini ($_modelName)...");
      final response = await _model.generateContent([prompt]);
      print("Gemini Response Recieved.");

      if (response.text != null) {
        return _parseBill(response.text!);
      }
      print("Gemini Response is Empty.");
      return null;
    } catch (e, stack) {
      print('!!! Gemini Error Occurred (Text) !!!');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      if (e is GenerativeAIException) {
         print('GenerativeAIException Details: ${e.message}');
      }
      print('Stack Trace: $stack');
      throw e;
    }
  }

  Bill _parseBill(String jsonString) {
    print("Gemini Response: $jsonString");
    // Clean up JSON string if it contains markdown code blocks
    String cleanJson = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
    
    final Map<String, dynamic> data = jsonDecode(cleanJson);
    
    String dueDate = data['dueDate'] ?? DateTime.now().toIso8601String().split('T')[0];
    dueDate = _normalizeDate(dueDate);

    return Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? '未知帳單',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'NT\$',
      dueDate: dueDate,
      status: BillStatus.unpaid,
      note: data['note'],
      category: data['category'],
      recurrence: data['recurrence'] != null 
          ? Recurrence.values[data['recurrence']] 
          : Recurrence.none,
    );
  }

  String _normalizeDate(String dateStr) {
    try {
      // Handle 112/03/19 or 112-03-19 -> 2023-03-19
      dateStr = dateStr.replaceAll('/', '-');
      List<String> parts = dateStr.split('-');
      if (parts.length == 3) {
        int year = int.parse(parts[0]);
        // If year is ROC (e.g., < 1920, assuming bills aren't from 1911), add 1911
        if (year < 1920) {
           year += 1911;
           dateStr = "$year-${parts[1]}-${parts[2]}";
        }
      }
      
      // Validate by trying to parse
      DateTime.parse(dateStr);
      return dateStr;
    } catch (e) {
      print("Date parsing error: $e. Input: $dateStr. Fallback to today.");
      return DateTime.now().toIso8601String().split('T')[0];
    }
  }
}
