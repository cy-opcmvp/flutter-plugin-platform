/// Service for plugin discovery and registry management
class PluginRegistryService {
  final Map<String, PluginRegistryEntry> _registry = {};

  /// Add a plugin to the registry
  void addPlugin(PluginRegistryEntry entry) {
    if (!entry.isValid()) {
      throw ArgumentError('Invalid plugin registry entry');
    }
    _registry[entry.pluginId] = entry;
  }

  /// Remove a plugin from the registry
  void removePlugin(String pluginId) {
    _registry.remove(pluginId);
  }

  /// Get plugin information from registry
  PluginRegistryEntry? getPluginInfo(String pluginId) {
    return _registry[pluginId];
  }

  /// Search plugins by query with advanced filtering
  List<PluginRegistryEntry> searchPlugins(
    String query, {
    String? category,
    List<String>? tags,
    String? author,
    String? minVersion,
    String? maxVersion,
    List<String>? supportedPlatforms,
    String? securityLevel,
    bool? isVerified,
  }) {
    var results = _registry.values.toList();

    // Apply text search filter
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((entry) {
        return entry.name.toLowerCase().contains(lowerQuery) ||
            entry.description.toLowerCase().contains(lowerQuery) ||
            entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
            entry.author.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Apply category filter
    if (category != null && category.isNotEmpty) {
      results = results
          .where(
            (entry) => entry.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    }

    // Apply tags filter
    if (tags != null && tags.isNotEmpty) {
      results = results.where((entry) {
        return tags.any(
          (tag) => entry.tags.any(
            (entryTag) => entryTag.toLowerCase() == tag.toLowerCase(),
          ),
        );
      }).toList();
    }

    // Apply author filter
    if (author != null && author.isNotEmpty) {
      results = results
          .where(
            (entry) =>
                entry.author.toLowerCase().contains(author.toLowerCase()),
          )
          .toList();
    }

    // Apply version filters
    if (minVersion != null) {
      results = results
          .where((entry) => _compareVersions(entry.version, minVersion) >= 0)
          .toList();
    }
    if (maxVersion != null) {
      results = results
          .where((entry) => _compareVersions(entry.version, maxVersion) <= 0)
          .toList();
    }

    // Apply platform filter
    if (supportedPlatforms != null && supportedPlatforms.isNotEmpty) {
      results = results.where((entry) {
        return supportedPlatforms.any(
          (platform) =>
              entry.compatibility.supportedPlatforms.contains(platform),
        );
      }).toList();
    }

    // Apply security level filter
    if (securityLevel != null && securityLevel.isNotEmpty) {
      results = results
          .where((entry) => entry.securityStatus.securityLevel == securityLevel)
          .toList();
    }

    // Apply verification filter
    if (isVerified != null) {
      results = results
          .where((entry) => entry.securityStatus.isVerified == isVerified)
          .toList();
    }

    return results;
  }

  /// Get all plugins in registry
  List<PluginRegistryEntry> getAllPlugins() {
    return _registry.values.toList();
  }

  /// Get plugins by category
  List<PluginRegistryEntry> getPluginsByCategory(String category) {
    return _registry.values
        .where((entry) => entry.category == category)
        .toList();
  }

  /// Check if plugin exists in registry
  bool hasPlugin(String pluginId) {
    return _registry.containsKey(pluginId);
  }

  /// Clear all plugins from registry
  void clear() {
    _registry.clear();
  }

  /// Get plugins sorted by popularity (download count)
  List<PluginRegistryEntry> getPopularPlugins({int limit = 10}) {
    final plugins = _registry.values.toList();
    plugins.sort(
      (a, b) =>
          b.statistics.downloadCount.compareTo(a.statistics.downloadCount),
    );
    return plugins.take(limit).toList();
  }

  /// Get plugins sorted by rating
  List<PluginRegistryEntry> getTopRatedPlugins({int limit = 10}) {
    final plugins = _registry.values.toList();
    plugins.sort(
      (a, b) =>
          b.statistics.averageRating.compareTo(a.statistics.averageRating),
    );
    return plugins.take(limit).toList();
  }

  /// Get recently updated plugins
  List<PluginRegistryEntry> getRecentlyUpdatedPlugins({int limit = 10}) {
    final plugins = _registry.values.toList();
    plugins.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return plugins.take(limit).toList();
  }

  /// Get all available categories
  List<String> getAvailableCategories() {
    final categories = <String>{};
    for (final entry in _registry.values) {
      categories.add(entry.category);
    }
    return categories.toList()..sort();
  }

  /// Get all available tags
  List<String> getAvailableTags() {
    final tags = <String>{};
    for (final entry in _registry.values) {
      tags.addAll(entry.tags);
    }
    return tags.toList()..sort();
  }

  /// Get all available authors
  List<String> getAvailableAuthors() {
    final authors = <String>{};
    for (final entry in _registry.values) {
      authors.add(entry.author);
    }
    return authors.toList()..sort();
  }

  /// Get plugin statistics summary
  PluginRegistryStatistics getRegistryStatistics() {
    if (_registry.isEmpty) {
      return PluginRegistryStatistics(
        totalPlugins: 0,
        totalDownloads: 0,
        averageRating: 0.0,
        categoryCounts: {},
        platformCounts: {},
      );
    }

    final categoryCounts = <String, int>{};
    final platformCounts = <String, int>{};
    var totalDownloads = 0;
    var totalRatingSum = 0.0;
    var ratedPluginCount = 0;

    for (final entry in _registry.values) {
      // Count categories
      categoryCounts[entry.category] =
          (categoryCounts[entry.category] ?? 0) + 1;

      // Count platforms
      for (final platform in entry.compatibility.supportedPlatforms) {
        platformCounts[platform] = (platformCounts[platform] ?? 0) + 1;
      }

      // Sum downloads and ratings
      totalDownloads += entry.statistics.downloadCount;
      if (entry.statistics.ratingCount > 0) {
        totalRatingSum += entry.statistics.averageRating;
        ratedPluginCount++;
      }
    }

    return PluginRegistryStatistics(
      totalPlugins: _registry.length,
      totalDownloads: totalDownloads,
      averageRating: ratedPluginCount > 0
          ? totalRatingSum / ratedPluginCount
          : 0.0,
      categoryCounts: categoryCounts,
      platformCounts: platformCounts,
    );
  }

  /// Update plugin metadata
  void updatePluginMetadata(String pluginId, Map<String, dynamic> metadata) {
    final entry = _registry[pluginId];
    if (entry == null) {
      throw ArgumentError('Plugin $pluginId not found in registry');
    }

    // Create updated entry with new metadata
    // In a real implementation, this would update specific fields
    // For now, we just update the lastUpdated timestamp
    final updatedEntry = PluginRegistryEntry(
      pluginId: entry.pluginId,
      name: metadata['name'] as String? ?? entry.name,
      version: metadata['version'] as String? ?? entry.version,
      description: metadata['description'] as String? ?? entry.description,
      category: metadata['category'] as String? ?? entry.category,
      tags: (metadata['tags'] as List<String>?) ?? entry.tags,
      downloadUrl: metadata['downloadUrl'] as String? ?? entry.downloadUrl,
      sourceUrl: metadata['sourceUrl'] as String? ?? entry.sourceUrl,
      securityStatus: entry.securityStatus,
      compatibility: entry.compatibility,
      statistics: entry.statistics,
      lastUpdated: DateTime.now(),
      author: metadata['author'] as String? ?? entry.author,
      license: metadata['license'] as String? ?? entry.license,
    );

    _registry[pluginId] = updatedEntry;
  }

  /// Bulk add plugins to registry
  void addPlugins(List<PluginRegistryEntry> entries) {
    for (final entry in entries) {
      addPlugin(entry);
    }
  }

  /// Export registry to JSON
  Map<String, dynamic> exportToJson() {
    return {
      'plugins': _registry.values.map((entry) => entry.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// Import registry from JSON
  void importFromJson(Map<String, dynamic> json) {
    final pluginsList = json['plugins'] as List<dynamic>;
    for (final pluginJson in pluginsList) {
      final entry = PluginRegistryEntry.fromJson(
        pluginJson as Map<String, dynamic>,
      );
      _registry[entry.pluginId] = entry;
    }
  }

  /// Resolve dependencies for a plugin
  List<PluginRegistryEntry> resolveDependencies(String pluginId) {
    final plugin = _registry[pluginId];
    if (plugin == null) {
      throw ArgumentError('Plugin $pluginId not found in registry');
    }

    final resolved = <String, PluginRegistryEntry>{};
    final visiting = <String>{};

    void _resolveDependenciesRecursive(String currentPluginId) {
      if (resolved.containsKey(currentPluginId)) {
        return; // Already resolved
      }

      if (visiting.contains(currentPluginId)) {
        throw StateError(
          'Circular dependency detected involving plugin $currentPluginId',
        );
      }

      visiting.add(currentPluginId);

      final currentPlugin = _registry[currentPluginId];
      if (currentPlugin == null) {
        throw ArgumentError(
          'Dependency $currentPluginId not found in registry',
        );
      }

      // Get dependencies from plugin metadata (simulated as tags starting with 'dep:')
      final dependencies = currentPlugin.tags
          .where((tag) => tag.startsWith('dep:'))
          .map((tag) => tag.substring(4))
          .toList();

      // Resolve each dependency first
      for (final depId in dependencies) {
        _resolveDependenciesRecursive(depId);
      }

      // Add current plugin to resolved list
      resolved[currentPluginId] = currentPlugin;
      visiting.remove(currentPluginId);
    }

    _resolveDependenciesRecursive(pluginId);

    // Return dependencies in resolution order (excluding the main plugin)
    final result = resolved.values.toList();
    result.removeWhere((entry) => entry.pluginId == pluginId);
    return result;
  }

  /// Get recommended plugins based on user preferences and plugin similarity
  List<PluginRegistryEntry> getRecommendedPlugins({
    String? basedOnPluginId,
    List<String>? userCategories,
    List<String>? userTags,
    int limit = 10,
  }) {
    var candidates = _registry.values.toList();

    // If based on a specific plugin, find similar plugins
    if (basedOnPluginId != null) {
      final basePlugin = _registry[basedOnPluginId];
      if (basePlugin != null) {
        candidates = _findSimilarPlugins(basePlugin, candidates);
      }
    }

    // Filter by user preferences
    if (userCategories != null && userCategories.isNotEmpty) {
      candidates = candidates
          .where((plugin) => userCategories.contains(plugin.category))
          .toList();
    }

    if (userTags != null && userTags.isNotEmpty) {
      candidates = candidates
          .where((plugin) => plugin.tags.any((tag) => userTags.contains(tag)))
          .toList();
    }

    // Score and sort candidates
    candidates = _scoreAndSortPlugins(candidates);

    return candidates.take(limit).toList();
  }

  /// Find plugins similar to a base plugin
  List<PluginRegistryEntry> _findSimilarPlugins(
    PluginRegistryEntry basePlugin,
    List<PluginRegistryEntry> candidates,
  ) {
    final scored = <_ScoredPlugin>[];

    for (final candidate in candidates) {
      if (candidate.pluginId == basePlugin.pluginId) continue;

      double score = 0.0;

      // Category match (high weight)
      if (candidate.category == basePlugin.category) {
        score += 0.4;
      }

      // Tag similarity (medium weight)
      final commonTags = candidate.tags
          .where((tag) => basePlugin.tags.contains(tag))
          .length;
      final totalTags = (candidate.tags.length + basePlugin.tags.length)
          .toDouble();
      if (totalTags > 0) {
        score += 0.3 * (2 * commonTags / totalTags);
      }

      // Author match (low weight)
      if (candidate.author == basePlugin.author) {
        score += 0.1;
      }

      // Platform compatibility (low weight)
      final commonPlatforms = candidate.compatibility.supportedPlatforms
          .where(
            (platform) =>
                basePlugin.compatibility.supportedPlatforms.contains(platform),
          )
          .length;
      final totalPlatforms =
          (candidate.compatibility.supportedPlatforms.length +
                  basePlugin.compatibility.supportedPlatforms.length)
              .toDouble();
      if (totalPlatforms > 0) {
        score += 0.2 * (2 * commonPlatforms / totalPlatforms);
      }

      scored.add(_ScoredPlugin(candidate, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((sp) => sp.plugin).toList();
  }

  /// Score and sort plugins by relevance and quality
  List<PluginRegistryEntry> _scoreAndSortPlugins(
    List<PluginRegistryEntry> plugins,
  ) {
    final scored = <_ScoredPlugin>[];

    for (final plugin in plugins) {
      double score = 0.0;

      // Rating score (0-1)
      score += plugin.statistics.averageRating / 5.0 * 0.3;

      // Popularity score (normalized by max downloads)
      final maxDownloads = plugins
          .map((p) => p.statistics.downloadCount)
          .reduce((a, b) => a > b ? a : b);
      if (maxDownloads > 0) {
        score += (plugin.statistics.downloadCount / maxDownloads) * 0.2;
      }

      // Recency score (newer plugins get slight boost)
      final daysSinceUpdate = DateTime.now()
          .difference(plugin.lastUpdated)
          .inDays;
      final recencyScore = (365 - daysSinceUpdate.clamp(0, 365)) / 365.0;
      score += recencyScore * 0.1;

      // Security score
      if (plugin.securityStatus.isVerified) score += 0.2;
      if (plugin.securityStatus.hasSignature) score += 0.1;
      if (plugin.securityStatus.securityWarnings.isEmpty) score += 0.1;

      scored.add(_ScoredPlugin(plugin, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((sp) => sp.plugin).toList();
  }

  /// Get trending plugins (high recent download activity)
  List<PluginRegistryEntry> getTrendingPlugins({int limit = 10}) {
    final plugins = _registry.values.toList();

    // Sort by a combination of recent activity and current popularity
    plugins.sort((a, b) {
      // Simple trending algorithm: recent updates + high downloads
      final aScore =
          a.statistics.downloadCount *
          (1.0 +
              (30 -
                      DateTime.now()
                          .difference(a.lastUpdated)
                          .inDays
                          .clamp(0, 30)) /
                  30.0);
      final bScore =
          b.statistics.downloadCount *
          (1.0 +
              (30 -
                      DateTime.now()
                          .difference(b.lastUpdated)
                          .inDays
                          .clamp(0, 30)) /
                  30.0);
      return bScore.compareTo(aScore);
    });

    return plugins.take(limit).toList();
  }

  /// Get featured plugins (curated selection)
  List<PluginRegistryEntry> getFeaturedPlugins({int limit = 10}) {
    final featured = _registry.values
        .where(
          (plugin) =>
              plugin.tags.contains('featured') ||
              (plugin.statistics.averageRating >= 4.5 &&
                  plugin.statistics.downloadCount >= 1000 &&
                  plugin.securityStatus.isVerified),
        )
        .toList();

    featured.sort(
      (a, b) =>
          b.statistics.averageRating.compareTo(a.statistics.averageRating),
    );
    return featured.take(limit).toList();
  }

  /// Advanced search with fuzzy matching and ranking
  List<PluginRegistryEntry> advancedSearch(
    String query, {
    String? category,
    List<String>? tags,
    String? author,
    String? minVersion,
    String? maxVersion,
    List<String>? supportedPlatforms,
    String? securityLevel,
    bool? isVerified,
    double minRating = 0.0,
    int minDownloads = 0,
    SortBy sortBy = SortBy.relevance,
    bool ascending = false,
    int limit = 50,
  }) {
    var results = searchPlugins(
      query,
      category: category,
      tags: tags,
      author: author,
      minVersion: minVersion,
      maxVersion: maxVersion,
      supportedPlatforms: supportedPlatforms,
      securityLevel: securityLevel,
      isVerified: isVerified,
    );

    // Apply additional filters
    results = results
        .where(
          (plugin) =>
              plugin.statistics.averageRating >= minRating &&
              plugin.statistics.downloadCount >= minDownloads,
        )
        .toList();

    // Apply fuzzy matching and scoring if query is provided
    if (query.isNotEmpty) {
      final scored = <_ScoredPlugin>[];
      for (final plugin in results) {
        final score = _calculateSearchScore(plugin, query);
        scored.add(_ScoredPlugin(plugin, score));
      }
      scored.sort((a, b) => b.score.compareTo(a.score));
      results = scored.map((sp) => sp.plugin).toList();
    } else {
      // Sort by specified criteria
      _sortPlugins(results, sortBy, ascending);
    }

    return results.take(limit).toList();
  }

  /// Calculate search relevance score for a plugin
  double _calculateSearchScore(PluginRegistryEntry plugin, String query) {
    final lowerQuery = query.toLowerCase();
    double score = 0.0;

    // Exact name match (highest score)
    if (plugin.name.toLowerCase() == lowerQuery) {
      score += 1.0;
    } else if (plugin.name.toLowerCase().contains(lowerQuery)) {
      score += 0.8;
    }

    // Description match
    if (plugin.description.toLowerCase().contains(lowerQuery)) {
      score += 0.6;
    }

    // Tag matches
    for (final tag in plugin.tags) {
      if (tag.toLowerCase().contains(lowerQuery)) {
        score += 0.4;
      }
    }

    // Author match
    if (plugin.author.toLowerCase().contains(lowerQuery)) {
      score += 0.3;
    }

    // Category match
    if (plugin.category.toLowerCase().contains(lowerQuery)) {
      score += 0.5;
    }

    // Boost score based on plugin quality
    score *= (1.0 + plugin.statistics.averageRating / 10.0);

    return score;
  }

  /// Sort plugins by specified criteria
  void _sortPlugins(
    List<PluginRegistryEntry> plugins,
    SortBy sortBy,
    bool ascending,
  ) {
    switch (sortBy) {
      case SortBy.name:
        plugins.sort(
          (a, b) =>
              ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
        );
        break;
      case SortBy.rating:
        plugins.sort(
          (a, b) => ascending
              ? a.statistics.averageRating.compareTo(b.statistics.averageRating)
              : b.statistics.averageRating.compareTo(
                  a.statistics.averageRating,
                ),
        );
        break;
      case SortBy.downloads:
        plugins.sort(
          (a, b) => ascending
              ? a.statistics.downloadCount.compareTo(b.statistics.downloadCount)
              : b.statistics.downloadCount.compareTo(
                  a.statistics.downloadCount,
                ),
        );
        break;
      case SortBy.updated:
        plugins.sort(
          (a, b) => ascending
              ? a.lastUpdated.compareTo(b.lastUpdated)
              : b.lastUpdated.compareTo(a.lastUpdated),
        );
        break;
      case SortBy.published:
        plugins.sort(
          (a, b) => ascending
              ? a.statistics.firstPublished.compareTo(
                  b.statistics.firstPublished,
                )
              : b.statistics.firstPublished.compareTo(
                  a.statistics.firstPublished,
                ),
        );
        break;
      case SortBy.relevance:
        // Already sorted by relevance in advancedSearch
        break;
    }
  }

  /// Get plugin suggestions based on partial input
  List<String> getPluginSuggestions(String partialQuery, {int limit = 10}) {
    final suggestions = <String>{};
    final lowerQuery = partialQuery.toLowerCase();

    for (final plugin in _registry.values) {
      // Add name suggestions
      if (plugin.name.toLowerCase().startsWith(lowerQuery)) {
        suggestions.add(plugin.name);
      }

      // Add tag suggestions
      for (final tag in plugin.tags) {
        if (tag.toLowerCase().startsWith(lowerQuery)) {
          suggestions.add(tag);
        }
      }

      // Add category suggestions
      if (plugin.category.toLowerCase().startsWith(lowerQuery)) {
        suggestions.add(plugin.category);
      }

      // Add author suggestions
      if (plugin.author.toLowerCase().startsWith(lowerQuery)) {
        suggestions.add(plugin.author);
      }
    }

    final sortedSuggestions = suggestions.toList()..sort();
    return sortedSuggestions.take(limit).toList();
  }

  /// Get category hierarchy for better organization
  Map<String, List<String>> getCategoryHierarchy() {
    final hierarchy = <String, List<String>>{};

    for (final plugin in _registry.values) {
      final category = plugin.category;
      final subcategories = plugin.tags
          .where((tag) => tag.startsWith('subcategory:'))
          .map((tag) => tag.substring(12))
          .toList();

      if (!hierarchy.containsKey(category)) {
        hierarchy[category] = <String>[];
      }

      for (final subcategory in subcategories) {
        if (!hierarchy[category]!.contains(subcategory)) {
          hierarchy[category]!.add(subcategory);
        }
      }
    }

    // Sort subcategories
    for (final subcategories in hierarchy.values) {
      subcategories.sort();
    }

    return hierarchy;
  }

  /// Get plugins by subcategory
  List<PluginRegistryEntry> getPluginsBySubcategory(
    String category,
    String subcategory,
  ) {
    return _registry.values
        .where(
          (plugin) =>
              plugin.category == category &&
              plugin.tags.contains('subcategory:$subcategory'),
        )
        .toList();
  }

  /// Get dependency tree for a plugin
  Map<String, List<String>> getDependencyTree(String pluginId) {
    final plugin = _registry[pluginId];
    if (plugin == null) {
      throw ArgumentError('Plugin $pluginId not found in registry');
    }

    final tree = <String, List<String>>{};
    final visited = <String>{};

    void _buildTree(String currentPluginId) {
      if (visited.contains(currentPluginId)) {
        return;
      }

      visited.add(currentPluginId);

      final currentPlugin = _registry[currentPluginId];
      if (currentPlugin == null) {
        return;
      }

      // Get dependencies from plugin metadata (simulated as tags starting with 'dep:')
      final dependencies = currentPlugin.tags
          .where((tag) => tag.startsWith('dep:'))
          .map((tag) => tag.substring(4))
          .where((depId) => _registry.containsKey(depId))
          .toList();

      tree[currentPluginId] = dependencies;

      // Recursively build tree for dependencies
      for (final depId in dependencies) {
        _buildTree(depId);
      }
    }

    _buildTree(pluginId);
    return tree;
  }

  /// Check if plugin has dependencies
  bool hasDependencies(String pluginId) {
    final plugin = _registry[pluginId];
    if (plugin == null) {
      return false;
    }

    return plugin.tags.any((tag) => tag.startsWith('dep:'));
  }

  /// Get direct dependencies of a plugin
  List<String> getDirectDependencies(String pluginId) {
    final plugin = _registry[pluginId];
    if (plugin == null) {
      throw ArgumentError('Plugin $pluginId not found in registry');
    }

    return plugin.tags
        .where((tag) => tag.startsWith('dep:'))
        .map((tag) => tag.substring(4))
        .toList();
  }

  /// Validate dependency chain for circular dependencies
  bool hasCircularDependencies(String pluginId) {
    try {
      resolveDependencies(pluginId);
      return false;
    } catch (e) {
      return e is StateError && e.message.contains('Circular dependency');
    }
  }

  /// Private helper method to compare semantic versions
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    // Pad with zeros if needed
    while (v1Parts.length < 3) v1Parts.add(0);
    while (v2Parts.length < 3) v2Parts.add(0);

    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }

    return 0;
  }
}

/// Registry entry containing plugin metadata and discovery information
class PluginRegistryEntry {
  final String pluginId;
  final String name;
  final String version;
  final String description;
  final String category;
  final List<String> tags;
  final String downloadUrl;
  final String sourceUrl;
  final SecurityStatus securityStatus;
  final CompatibilityInfo compatibility;
  final PluginStatistics statistics;
  final DateTime lastUpdated;
  final String author;
  final String license;

  const PluginRegistryEntry({
    required this.pluginId,
    required this.name,
    required this.version,
    required this.description,
    required this.category,
    required this.tags,
    required this.downloadUrl,
    required this.sourceUrl,
    required this.securityStatus,
    required this.compatibility,
    required this.statistics,
    required this.lastUpdated,
    required this.author,
    required this.license,
  });

  /// Validate registry entry completeness
  bool isValid() {
    // All required fields must be non-empty
    if (pluginId.isEmpty ||
        name.isEmpty ||
        version.isEmpty ||
        description.isEmpty ||
        category.isEmpty ||
        downloadUrl.isEmpty ||
        author.isEmpty ||
        license.isEmpty) {
      return false;
    }

    // URLs must be valid
    final downloadUri = Uri.tryParse(downloadUrl);
    if (downloadUri == null || !downloadUri.hasAbsolutePath) {
      return false;
    }

    if (sourceUrl.isNotEmpty) {
      final sourceUri = Uri.tryParse(sourceUrl);
      if (sourceUri == null || !sourceUri.hasAbsolutePath) {
        return false;
      }
    }

    // Version must be valid
    if (!RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$').hasMatch(version)) {
      return false;
    }

    // Security status and compatibility must be valid
    if (!securityStatus.isValid() || !compatibility.isValid()) {
      return false;
    }

    return true;
  }

  factory PluginRegistryEntry.fromJson(Map<String, dynamic> json) {
    return PluginRegistryEntry(
      pluginId: json['pluginId'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      downloadUrl: json['downloadUrl'] as String,
      sourceUrl: json['sourceUrl'] as String? ?? '',
      securityStatus: SecurityStatus.fromJson(
        json['securityStatus'] as Map<String, dynamic>,
      ),
      compatibility: CompatibilityInfo.fromJson(
        json['compatibility'] as Map<String, dynamic>,
      ),
      statistics: PluginStatistics.fromJson(
        json['statistics'] as Map<String, dynamic>,
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      author: json['author'] as String,
      license: json['license'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'name': name,
      'version': version,
      'description': description,
      'category': category,
      'tags': tags,
      'downloadUrl': downloadUrl,
      'sourceUrl': sourceUrl,
      'securityStatus': securityStatus.toJson(),
      'compatibility': compatibility.toJson(),
      'statistics': statistics.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'author': author,
      'license': license,
    };
  }
}

/// Security status information for registry entries
class SecurityStatus {
  final bool isVerified;
  final bool hasSignature;
  final String securityLevel;
  final List<String> securityWarnings;
  final DateTime? lastSecurityScan;
  final bool requiresSignature;

  const SecurityStatus({
    required this.isVerified,
    required this.hasSignature,
    required this.securityLevel,
    required this.securityWarnings,
    this.lastSecurityScan,
    this.requiresSignature = false,
  });

  bool isValid() {
    final validLevels = ['low', 'medium', 'high', 'critical'];
    return validLevels.contains(securityLevel);
  }

  factory SecurityStatus.fromJson(Map<String, dynamic> json) {
    return SecurityStatus(
      isVerified: json['isVerified'] as bool,
      hasSignature: json['hasSignature'] as bool,
      securityLevel: json['securityLevel'] as String,
      securityWarnings: (json['securityWarnings'] as List<dynamic>)
          .cast<String>(),
      lastSecurityScan: json['lastSecurityScan'] != null
          ? DateTime.parse(json['lastSecurityScan'] as String)
          : null,
      requiresSignature: json['requiresSignature'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isVerified': isVerified,
      'hasSignature': hasSignature,
      'securityLevel': securityLevel,
      'securityWarnings': securityWarnings,
      'lastSecurityScan': lastSecurityScan?.toIso8601String(),
      'requiresSignature': requiresSignature,
    };
  }
}

/// Compatibility information for registry entries
class CompatibilityInfo {
  final List<String> supportedPlatforms;
  final String minHostVersion;
  final String? maxHostVersion;
  final List<String> requiredFeatures;
  final Map<String, String> systemRequirements;

  const CompatibilityInfo({
    required this.supportedPlatforms,
    required this.minHostVersion,
    this.maxHostVersion,
    required this.requiredFeatures,
    required this.systemRequirements,
  });

  bool isValid() {
    // Must support at least one platform
    if (supportedPlatforms.isEmpty) {
      return false;
    }

    // Version must be valid
    if (!RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$').hasMatch(minHostVersion)) {
      return false;
    }

    if (maxHostVersion != null &&
        !RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$').hasMatch(maxHostVersion!)) {
      return false;
    }

    return true;
  }

  factory CompatibilityInfo.fromJson(Map<String, dynamic> json) {
    return CompatibilityInfo(
      supportedPlatforms: (json['supportedPlatforms'] as List<dynamic>)
          .cast<String>(),
      minHostVersion: json['minHostVersion'] as String,
      maxHostVersion: json['maxHostVersion'] as String?,
      requiredFeatures: (json['requiredFeatures'] as List<dynamic>)
          .cast<String>(),
      systemRequirements: (json['systemRequirements'] as Map<String, dynamic>)
          .cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supportedPlatforms': supportedPlatforms,
      'minHostVersion': minHostVersion,
      'maxHostVersion': maxHostVersion,
      'requiredFeatures': requiredFeatures,
      'systemRequirements': systemRequirements,
    };
  }
}

/// Plugin statistics for registry entries
class PluginStatistics {
  final int downloadCount;
  final double averageRating;
  final int ratingCount;
  final int activeInstalls;
  final DateTime firstPublished;

  const PluginStatistics({
    required this.downloadCount,
    required this.averageRating,
    required this.ratingCount,
    required this.activeInstalls,
    required this.firstPublished,
  });

  factory PluginStatistics.fromJson(Map<String, dynamic> json) {
    return PluginStatistics(
      downloadCount: json['downloadCount'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      activeInstalls: json['activeInstalls'] as int,
      firstPublished: DateTime.parse(json['firstPublished'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadCount': downloadCount,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'activeInstalls': activeInstalls,
      'firstPublished': firstPublished.toIso8601String(),
    };
  }
}

/// Sort criteria for plugin search results
enum SortBy { relevance, name, rating, downloads, updated, published }

/// Helper class for scoring plugins
class _ScoredPlugin {
  final PluginRegistryEntry plugin;
  final double score;

  const _ScoredPlugin(this.plugin, this.score);
}

/// Registry statistics summary
class PluginRegistryStatistics {
  final int totalPlugins;
  final int totalDownloads;
  final double averageRating;
  final Map<String, int> categoryCounts;
  final Map<String, int> platformCounts;

  const PluginRegistryStatistics({
    required this.totalPlugins,
    required this.totalDownloads,
    required this.averageRating,
    required this.categoryCounts,
    required this.platformCounts,
  });

  factory PluginRegistryStatistics.fromJson(Map<String, dynamic> json) {
    return PluginRegistryStatistics(
      totalPlugins: json['totalPlugins'] as int,
      totalDownloads: json['totalDownloads'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      categoryCounts: (json['categoryCounts'] as Map<String, dynamic>)
          .cast<String, int>(),
      platformCounts: (json['platformCounts'] as Map<String, dynamic>)
          .cast<String, int>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPlugins': totalPlugins,
      'totalDownloads': totalDownloads,
      'averageRating': averageRating,
      'categoryCounts': categoryCounts,
      'platformCounts': platformCounts,
    };
  }
}
