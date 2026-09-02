/// Resolves the TMDB API key from compile-time environment defines.
String resolveTmdbApiKey() {
  const tmdbKey = String.fromEnvironment('TMDB_API_KEY');
  if (tmdbKey.isNotEmpty) return tmdbKey;

  const devKey = String.fromEnvironment('DEV_TMDB_API_KEY');
  if (devKey.isNotEmpty) return devKey;

  return '';
}
