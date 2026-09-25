import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart' as http;

/// The default browser client buffers whole responses; fetch streams them.
http.Client createClient() => FetchClient(mode: RequestMode.cors);

/// Browsers forbid a page from setting User-Agent: the fetch would be rejected.
const bool canSetUserAgent = false;
