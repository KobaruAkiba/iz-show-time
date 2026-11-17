/// Where a title currently lives; the catalogue wins over the watchlist.
enum LibraryStatus { none, watchlist, catalogue }

/// Outcome of the Search bookmark, used to pick the feedback message.
enum LibraryToggleResult {
  addedToCatalogue,
  removedFromCatalogue,
  addedToWatchlist,
  alreadyOnWatchlist,
}
