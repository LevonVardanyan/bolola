import 'package:politicsstatements/redesign/resources/repository.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';

import 'models/media_category.dart';
import 'models/media_group.dart';
import 'models/media_item.dart';
import 'models/medias.dart';
import 'models/sources.dart';

List<MediaItem> selectedItems = [];

Medias? medias;

List<MediaItem> favorites = [];
List<MediaItem> chartList = [];

Set<MediaItem> allItems = {};

List<SourceLinkItem> sourceLinks = [
  SourceLinkItem(name: "Ազատություն Ռադիոկայան", url: "https://www.youtube.com/user/azatutyunradio"),
  SourceLinkItem(name: "CivilNetTV", url: "https://www.youtube.com/user/CivilNetTV"),
  SourceLinkItem(name: "Գոռ Վարդանյան", url: "https://www.facebook.com/gorvardanyandirector/"),
  SourceLinkItem(name: "Կարգին TV", url: "https://www.youtube.com/user/KarginTV"),
  SourceLinkItem(name: "Կիսաբաց Լուսամուտներ", url: "https://www.youtube.com/user/KlisabacLusamutner"),
  SourceLinkItem(name: "Շարմ հոլդինգ", url: "https://www.youtube.com/user/sharmholding"),
];

int searchByMistake = 0;

MediaItem? findItemByAlias(String itemAlias, String groupAlias, String categoryAlias) {
  for (MediaCategory category in medias?.categories ?? []) {
    if (category.alias == categoryAlias) {
      for (MediaGroup group in category.groups ?? []) {
        if (group.alias == groupAlias) {
          for (MediaItem item in group.items ?? []) {
            if (item.alias == itemAlias) return item;
          }
        }
      }
    }
  }
  return null;
}

MediaGroup? findGroupByAlias(String groupAlias, String categoryAlias) {
  for (MediaCategory category in medias?.categories ?? []) {
    if (category.alias == categoryAlias) {
      for (MediaGroup group in category.groups ?? []) {
        if (group.alias == groupAlias) {
          return group;
        }
      }
    }
  }
  return null;
}

MediaItem? findChartItem(String itemAlias) {
  for (MediaItem item in chartList ?? []) {
    if (item.alias == itemAlias) return item;
  }
  return null;
}

List<MediaItem> findModeratingItems(String mediaType) {
  List<MediaItem> items = [];
  for (MediaCategory category in medias?.categories ?? []) {
    for (MediaGroup group in category.groups ?? []) {
      for (MediaItem item in group.items ?? []) {
        if (item.suggestedKeywords?.isNotEmpty == true) items.add(item);
      }
    }
  }
  return items;
}

List<MediaItem> searchInMediaList(String query, String sort, List<MediaItem> items) {
  List<MediaItem> primaryEqualFoundItems = [];
  List<MediaItem> primaryContainFoundItems = [];
  for (MediaItem mediaItem in items) {
    List<String> keywords = [];
    keywords.addAll(mediaItem.allKeywords ?? []);
    List<String> splitKeywords = [];
    String concatKeywords = "";
    mediaItem.allKeywords?.forEach((element) {
      splitKeywords.addAll(element.split(" "));
      concatKeywords += " $element";
    });

    var replacedMistakesQuery = repository.replaceMistakesEnglishForSearch(repository.replaceArmenianForSearch(query).toLowerCase());
    var replacedAllQuery = repository.replaceAllEnglishForSearch(repository.replaceArmenianForSearch(query).toLowerCase());
    List<String> replacedMistakesQuerySplit = replacedMistakesQuery.split(" ");
    replacedMistakesQuerySplit.remove("");
    List<String> replacedAllQuerySplit = replacedAllQuery.split(" ");
    replacedAllQuerySplit.remove("");

    if (concatKeywords.contains(replacedMistakesQuery) || concatKeywords.contains(replacedAllQuery)) {
      if (!primaryEqualFoundItems.contains(mediaItem)) {
        primaryEqualFoundItems.add(mediaItem);
        continue;
      }
    }

    bool containsAll = true;
    for (int l = 0; l < replacedAllQuerySplit.length; l++) {
      bool contains = false;
      for (int p = 0; p < splitKeywords.length; p++) {
        if (splitKeywords[p].contains(replacedAllQuerySplit[l]) || splitKeywords.contains(replacedMistakesQuerySplit[l])) {
          contains = true;
          break;
        }
      }
      if (!contains) {
        containsAll = false;
        break;
      }
    }
    if (containsAll && !primaryContainFoundItems.contains(mediaItem) && !primaryEqualFoundItems.contains(mediaItem)) {
      primaryContainFoundItems.add(mediaItem);
      continue;
    }
  }

  primaryEqualFoundItems.sort((a, b) {
    return sort == SEARCH_SORT_TYPE_ORDER ? a.name!.length - b.name!.length : b.shareCount! - a.shareCount!;
  });
  primaryContainFoundItems.sort((a, b) {
    return sort == SEARCH_SORT_TYPE_ORDER ? a.name!.length - b.name!.length : b.shareCount! - a.shareCount!;
  });
  List<MediaItem> resultItems = [];
  resultItems.addAll(primaryEqualFoundItems);
  resultItems.addAll(primaryContainFoundItems);
  return resultItems;
}

/// Update favorites and chartList with latest data from allItems source
/// This ensures that after admin updates, the favorites and top chart pages show updated information
void updateFavoritesAndChartFromSource() {
  // Update favorites list with data from allItems
  for (int i = 0; i < favorites.length; i++) {
    MediaItem favoriteItem = favorites[i];
    MediaItem? sourceItem = allItems.firstWhere(
      (item) => item.alias == favoriteItem.alias,
      orElse: () => favoriteItem,
    );
    
    if (sourceItem != favoriteItem) {
      // Update the favorite item with fresh data from source while preserving favorite status
      sourceItem.isFavorite = true;
      favorites[i] = sourceItem;
    }
  }
  
  // Update chartList with data from allItems
  for (int i = 0; i < chartList.length; i++) {
    MediaItem chartItem = chartList[i];
    MediaItem? sourceItem = allItems.firstWhere(
      (item) => item.alias == chartItem.alias,
      orElse: () => chartItem,
    );
    
    if (sourceItem != chartItem) {
      // Preserve the share count from chart and update other fields from source
      int? originalShareCount = chartItem.shareCount;
      chartList[i] = sourceItem;
      chartList[i].shareCount = originalShareCount;
    }
  }
  
  // Re-sort chartList by share count
  chartList.sort((a, b) => b.shareCount! - a.shareCount!);
}
