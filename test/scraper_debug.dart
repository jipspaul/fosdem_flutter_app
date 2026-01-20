import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  print('🔍 Testing FOSDEM Event Scraper...\n');
  
  // Test with a real event URL
  final eventUrl = 'https://fosdem.org/2024/schedule/event/fosdem-2024-3023-welcome-to-fosdem-2024/';
  
  print('📡 Fetching: $eventUrl');
  
  try {
    final response = await http.get(Uri.parse(eventUrl));
    
    print('📊 Status Code: ${response.statusCode}');
    print('📏 Content Length: ${response.body.length} bytes\n');
    
    if (response.statusCode == 200) {
      final document = parser.parse(response.body);
      
      // Extract title
      final title = document.querySelector('h2')?.text.trim();
      print('📌 Title: $title');
      
      // Extract description
      final description = document.querySelector('.event-description')?.text.trim();
      print('📝 Description length: ${description?.length ?? 0} chars');
      
      // Extract abstract
      final abstract = document.querySelector('.event-abstract')?.text.trim();
      print('📄 Abstract length: ${abstract?.length ?? 0} chars');
      
      // Extract speakers
      final speakerElements = document.querySelectorAll('.event-speaker');
      print('👥 Speakers found: ${speakerElements.length}');
      for (var speaker in speakerElements) {
        print('  - ${speaker.text.trim()}');
      }
      
      // Extract attachments
      final attachments = document.querySelectorAll('.event-attachment a');
      print('📎 Attachments found: ${attachments.length}');
      for (var attachment in attachments) {
        print('  - ${attachment.text.trim()} -> ${attachment.attributes['href']}');
      }
      
      // Extract links
      final links = document.querySelectorAll('.event-links a');
      print('🔗 Links found: ${links.length}');
      for (var link in links) {
        print('  - ${link.text.trim()} -> ${link.attributes['href']}');
      }
      
      print('\n✅ Scraper test completed successfully!');
    } else {
      print('❌ Failed to fetch page');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
