import 'package:http/http.dart' as http;

http.Client createClient() => http.Client();

/// Off the browser we may set any header, User-Agent included.
const bool canSetUserAgent = true;
