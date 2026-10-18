final Map<String, String> _sessionValues = {};

String? read(String key) => _sessionValues[key];

void write(String key, String value) {
  _sessionValues[key] = value;
}

void remove(String key) {
  _sessionValues.remove(key);
}
