import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/payment_repository.dart';

/// Only the gateway session enters the embedded form; account JWT stays in Dio.
String paymentCardHtml(PaymentSession session) {
  final config =
      jsonEncode({
            'sessionId': session.id,
            'countryCode': session.country,
            'cardViewId': 'mf-card-view',
            'supportedNetworks': 'v,m,md,ae',
          })
          .replaceAll('<', r'\u003c')
          .replaceAll("'", r'\u0027')
          .replaceAll('&', r'\u0026');
  return '''<!doctype html><html dir="rtl"><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{margin:0;background:white}#mf-card-view{min-height:260px}</style></head><body><div id="mf-card-view"></div>
<script>
window.addEventListener('message',function(event){
  var origin;try{origin=new URL(event.origin);}catch(e){return;}
  if(origin.protocol!=='https:' || !(origin.hostname==='myfatoorah.com' || origin.hostname.endsWith('.myfatoorah.com')))return;
  var msg=event.data;try{if(typeof msg==='string')msg=JSON.parse(msg);}catch(e){return;}
  if(!msg || msg.sender!=='CardView')return;
  if(msg.type===1 && msg.data?.IsSuccess && typeof msg.data.Data?.SessionId==='string') PaymentCard.postMessage(JSON.stringify({sessionId:msg.data.Data.SessionId}));
  else if(msg.type===2 || msg.data?.IsSuccess===false)PaymentCard.postMessage(JSON.stringify({error:true}));
});
function pay(){Promise.resolve(window.myFatoorah.submit()).catch(()=>PaymentCard.postMessage(JSON.stringify({error:true})));}
</script><script src="${session.cardOrigin}/cardview/v2/session.js" onload='window.myFatoorah.init($config);PaymentCard.postMessage(JSON.stringify({ready:true}));' onerror='PaymentCard.postMessage(JSON.stringify({error:true}));'></script></body></html>''';
}

class PaymentCardFrame extends StatefulWidget {
  final PaymentSession session;
  final ValueChanged<WebViewController> onController;
  final ValueChanged<String> onSession;
  final VoidCallback onReady, onError;
  const PaymentCardFrame({
    super.key,
    required this.session,
    required this.onController,
    required this.onSession,
    required this.onReady,
    required this.onError,
  });
  @override
  State<PaymentCardFrame> createState() => _PaymentCardFrameState();
}

class _PaymentCardFrameState extends State<PaymentCardFrame> {
  late final WebViewController controller;
  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'PaymentCard',
        onMessageReceived: (message) {
          if (!mounted) return;
          try {
            final body = jsonDecode(message.message);
            if (body['ready'] == true) {
              widget.onReady();
            } else if (body['sessionId'] is String) {
              widget.onSession(body['sessionId']);
            } else {
              widget.onError();
            }
          } catch (_) {
            widget.onError();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.scheme == 'about' || uri.scheme == 'data') {
              return NavigationDecision.navigate;
            }
            return uri.scheme == 'https' &&
                    (uri.host == 'myfatoorah.com' ||
                        uri.host.endsWith('.myfatoorah.com'))
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) widget.onError();
          },
        ),
      )
      ..loadHtmlString(
        paymentCardHtml(widget.session),
        baseUrl: widget.session.cardOrigin,
      );
    widget.onController(controller);
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 300, child: WebViewWidget(controller: controller));
}
