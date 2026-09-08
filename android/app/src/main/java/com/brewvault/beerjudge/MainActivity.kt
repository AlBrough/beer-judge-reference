package com.brewvault.beerjudge

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import org.json.JSONObject

data class BeerStyle(val id: String, val number: String, val name: String, val category: String, val categoryNumber: String, val metrics: List<Pair<String, String>>, val sections: List<Pair<String, String>>)

private fun naturalStyleKey(value: String): String = value.lowercase().replace(Regex("\\d+")) { it.value.padStart(4, '0') }

private fun sortedStyles(styles: List<BeerStyle>): List<BeerStyle> = styles.sortedWith(
    compareBy<BeerStyle> { it.categoryNumber.toIntOrNull() ?: Int.MAX_VALUE }
        .thenBy { it.category.lowercase() }
        .thenBy { naturalStyleKey(it.number) }
        .thenBy { it.name.lowercase() }
)

private data class StyleCategory(val number: String, val name: String, val styles: List<BeerStyle>)

private fun groupedStyles(styles: List<BeerStyle>): List<StyleCategory> = sortedStyles(styles)
    .groupBy { "${it.categoryNumber}|${it.category}" }
    .values
    .map { group -> StyleCategory(group.first().categoryNumber, group.first().category, sortedStyles(group)) }
    .sortedWith(compareBy<StyleCategory> { it.number.toIntOrNull() ?: Int.MAX_VALUE }.thenBy { it.name.lowercase() })

private fun display(value: String): String = value
    .replace(Regex("\\bipa\\b", RegexOption.IGNORE_CASE), "IPA")
    .replace(Regex("\\s*[â€“â€”-]\\s*"), " - ")

private fun categoryDisplay(value: String): String = when {
    value.equals("MEAD", true) -> "Mead"
    value.equals("CIDER", true) -> "Cider"
    else -> display(value)
}

private fun readStyles(activity: ComponentActivity, file: String): List<BeerStyle> {
    val root = JSONObject(activity.assets.open(file).bufferedReader().use { it.readText() })
    val styles = root.optJSONArray("styles") ?: return emptyList()
    return (0 until styles.length()).map { index ->
        val item = styles.getJSONObject(index)
        val metrics = item.optJSONArray("metrics")?.let { array -> (0 until array.length()).map { i ->
            val metric = array.getJSONObject(i); metric.optString("label") to display(metric.optString("value"))
        } } ?: emptyList()
        val sections = item.optJSONArray("sections")?.let { array -> (0 until array.length()).map { i ->
            val section = array.getJSONObject(i); section.optString("title") to section.optString("body")
        } } ?: emptyList()
        BeerStyle(item.optString("id"), item.optString("number"), item.optString("name"), item.optString("category"), item.optString("categoryNumber"), metrics, sections)
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { BeerJudgeApp(this) }
    }
}

private enum class Appearance(val label: String) { SYSTEM("System"), LIGHT("Light"), DARK("Dark") }
private enum class ColourTheme(val label: String) { FOREST("Forest"), OCEAN("Ocean"), AMBER("Amber"), NEUTRAL("Neutral") }

private val JudgeLightColors = lightColorScheme(primary = Color(0xFF6849A6), onPrimary = Color.White, surface = Color(0xFFFFF7FF), background = Color(0xFFFFF7FF), surfaceVariant = Color(0xFFE9E1EB))
private val JudgeDarkColors = darkColorScheme(primary = Color(0xFFD0BCFF), onPrimary = Color(0xFF382060), surface = Color(0xFF151218), background = Color(0xFF151218), surfaceVariant = Color(0xFF49454F))

private fun colours(theme: ColourTheme, dark: Boolean) = when (theme) {
    ColourTheme.FOREST -> if (dark) darkColorScheme(primary = Color(0xFF8FD3A8), surface = Color(0xFF0D1B13), background = Color(0xFF0D1B13)) else lightColorScheme(primary = Color(0xFF176B3A), surface = Color(0xFFF4FBF5), background = Color(0xFFF4FBF5))
    ColourTheme.OCEAN -> if (dark) darkColorScheme(primary = Color(0xFF91C9FF), surface = Color(0xFF0A1926), background = Color(0xFF0A1926)) else lightColorScheme(primary = Color(0xFF1769AA), surface = Color(0xFFF3F9FF), background = Color(0xFFF3F9FF))
    ColourTheme.AMBER -> if (dark) darkColorScheme(primary = Color(0xFFFFC66D), surface = Color(0xFF21170C), background = Color(0xFF21170C)) else lightColorScheme(primary = Color(0xFF9A5B00), surface = Color(0xFFFFF8EF), background = Color(0xFFFFF8EF))
    ColourTheme.NEUTRAL -> if (dark) JudgeDarkColors else lightColorScheme(primary = Color(0xFF53565A), surface = Color(0xFFF7F7F7), background = Color(0xFFF7F7F7))
}

@OptIn(ExperimentalMaterial3Api::class)
@androidx.compose.runtime.Composable
private fun BeerJudgeApp(activity: ComponentActivity) {
    val editions = listOf("BJCP 2021" to "bjcp-2021.json", "AABC 2025" to "aabc-2025.json", "BA 2026" to "ba-2026.json")
    var selected by remember { mutableStateOf(editions.first()) }
    var styles by remember(selected) { mutableStateOf(readStyles(activity, selected.second)) }
    var query by remember { mutableStateOf("") }
    var opened by remember { mutableStateOf<BeerStyle?>(null) }
    var openedCategory by remember { mutableStateOf<StyleCategory?>(null) }
    var showSettings by remember { mutableStateOf(false) }
    var tab by rememberSaveable { mutableStateOf("Browse") }
    var favourites by rememberSaveable { mutableStateOf(setOf<String>()) }
    var recents by rememberSaveable { mutableStateOf(listOf<String>()) }
    var appearance by rememberSaveable { mutableStateOf(activity.getPreferences(0).getString("appearance", Appearance.SYSTEM.name) ?: Appearance.SYSTEM.name) }
    var colourTheme by rememberSaveable { mutableStateOf(activity.getPreferences(0).getString("colourTheme", ColourTheme.FOREST.name) ?: ColourTheme.FOREST.name) }
    LaunchedEffect(appearance) { activity.getPreferences(0).edit().putString("appearance", appearance).apply() }
    LaunchedEffect(colourTheme) { activity.getPreferences(0).edit().putString("colourTheme", colourTheme).apply() }
    val selectedAppearance = Appearance.values().firstOrNull { it.name == appearance } ?: Appearance.SYSTEM
    val dark = when (selectedAppearance) { Appearance.SYSTEM -> isSystemInDarkTheme(); Appearance.LIGHT -> false; Appearance.DARK -> true }
    val selectedColourTheme = ColourTheme.values().firstOrNull { it.name == colourTheme } ?: ColourTheme.FOREST
    val filtered = sortedStyles(styles.filter { query.isBlank() || listOf(it.number, it.name, it.category).joinToString(" ").contains(query, ignoreCase = true) })
    val recentStyles = recents.mapNotNull { id -> styles.firstOrNull { it.id == id } }

    MaterialTheme(colorScheme = colours(selectedColourTheme, dark)) {
        Surface(Modifier.fillMaxSize()) {
            if (showSettings) SettingsScreen(selected, editions, selectedAppearance, selectedColourTheme, { edition -> selected = edition; styles = readStyles(activity, edition.second); query = "" }, { appearance = it.name }, { colourTheme = it.name }, { showSettings = false })
            else if (opened != null) StyleDetail(opened!!, favourites.contains(opened!!.id), { favourites = if (favourites.contains(opened!!.id)) favourites - opened!!.id else favourites + opened!!.id }) { opened = null }
            else if (openedCategory != null) CategoryDetail(openedCategory!!, { openedCategory = null }) { opened = it; recents = (listOf(it.id) + recents).distinct().take(8) }
            else if (tab == "Saved") SavedScreen(styles.filter { favourites.contains(it.id) }) { opened = it; recents = (listOf(it.id) + recents).distinct().take(8) }
            else if (tab == "Compare") CompareScreen(styles) { opened = it }
            else {
                var settingsOpen by remember { mutableStateOf(false) }
                Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
                    TopAppBar(title = { Text("Beer Judge Reference") }, actions = {
                        Box {
                            IconButton(onClick = { showSettings = true }) { Icon(Icons.Default.Settings, contentDescription = "Settings") }
                            DropdownMenu(expanded = settingsOpen, onDismissRequest = { settingsOpen = false }) { DropdownMenuItem(text = { Text("Open Settings") }, onClick = { settingsOpen = false; showSettings = true }) }
                        }
                    })
                    Column(Modifier.weight(1f).padding(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedTextField(value = query, onValueChange = { query = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Search styles") }, singleLine = true)
                        if (query.isBlank() && recentStyles.isNotEmpty()) {
                            Text("Recently opened", style = MaterialTheme.typography.titleMedium)
                            recentStyles.take(4).forEach { style -> TextButton(onClick = { opened = style }) { Text("${style.number} ${display(style.name)}") } }
                        }
                        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            items(if (selected.first.startsWith("AABC")) listOf(StyleCategory("", "AABC 2025", filtered)) else groupedStyles(filtered), key = { "${it.number}|${it.name}" }) { category ->
                                Card(onClick = { openedCategory = category }, modifier = Modifier.fillMaxWidth()) {
                                    Text(if (category.number.isBlank()) categoryDisplay(category.name) else "${category.number} ${categoryDisplay(category.name)}", modifier = Modifier.padding(16.dp), style = MaterialTheme.typography.titleMedium)
                                }
                            }
                        }
                    }
                    NavigationBar {
                        NavigationBarItem(selected = tab == "Browse", onClick = { tab = "Browse" }, icon = { Text("▦") }, label = { Text("Browse") })
                        NavigationBarItem(selected = tab == "Compare", onClick = { tab = "Compare" }, icon = { Text("⇄") }, label = { Text("Compare") })
                        NavigationBarItem(selected = tab == "Saved", onClick = { tab = "Saved" }, icon = { Text("★") }, label = { Text("Saved") })
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@androidx.compose.runtime.Composable
private fun SettingsScreen(selected: Pair<String, String>, editions: List<Pair<String, String>>, appearance: Appearance, colourTheme: ColourTheme, onGuideline: (Pair<String, String>) -> Unit, onAppearance: (Appearance) -> Unit, onColourTheme: (ColourTheme) -> Unit, onBack: () -> Unit) {
    var guidelineOpen by remember { mutableStateOf(false) }
    var appearanceOpen by remember { mutableStateOf(false) }
    var colourOpen by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
        TopAppBar(title = { Text("Settings") }, navigationIcon = { TextButton(onClick = onBack) { Text("Back") } })
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Guideline", style = MaterialTheme.typography.titleMedium)
            Box { Button(onClick = { guidelineOpen = true }) { Text(selected.first) }; DropdownMenu(guidelineOpen, { guidelineOpen = false }) { editions.forEach { edition -> DropdownMenuItem(text = { Text(edition.first) }, onClick = { onGuideline(edition); guidelineOpen = false }) } } }
            Text("Appearance", style = MaterialTheme.typography.titleMedium)
            Box { Button(onClick = { appearanceOpen = true }) { Text(appearance.label) }; DropdownMenu(appearanceOpen, { appearanceOpen = false }) { Appearance.values().forEach { option -> DropdownMenuItem(text = { Text(option.label) }, onClick = { onAppearance(option); appearanceOpen = false }) } } }
            Text("Colour theme", style = MaterialTheme.typography.titleMedium)
            Box { Button(onClick = { colourOpen = true }) { Text(colourTheme.label) }; DropdownMenu(colourOpen, { colourOpen = false }) { ColourTheme.values().forEach { option -> DropdownMenuItem(text = { Text(option.label) }, onClick = { onColourTheme(option); colourOpen = false }) } } }
            Text("© AB Labs", modifier = Modifier.padding(top = 24.dp), style = MaterialTheme.typography.bodySmall)
        }
    }
}

@androidx.compose.runtime.Composable
private fun SavedScreen(styles: List<BeerStyle>, onOpen: (BeerStyle) -> Unit) {
    Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
        TopAppBar(title = { Text("Saved") })
        if (styles.isEmpty()) Text("No saved styles", modifier = Modifier.padding(16.dp)) else LazyColumn(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) { items(styles, key = { it.id }) { style -> Card(onClick = { onOpen(style) }, modifier = Modifier.fillMaxWidth()) { Column(Modifier.padding(14.dp)) { Text("${style.number} ${display(style.name)}", style = MaterialTheme.typography.titleMedium); Text(categoryDisplay(style.category), style = MaterialTheme.typography.bodySmall) } } } }
    }
}

@androidx.compose.runtime.Composable
private fun CompareScreen(styles: List<BeerStyle>, onOpen: (BeerStyle) -> Unit) {
    var first by remember { mutableStateOf<BeerStyle?>(null) }
    var second by remember { mutableStateOf<BeerStyle?>(null) }
    Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Compare", style = MaterialTheme.typography.headlineSmall)
        Text("Choose two styles to compare their vital statistics and descriptions.")
        StyleChoice("First style", first, styles) { first = it }
        StyleChoice("Second style", second, styles) { second = it }
        if (first != null && second != null) {
            Text("Style", style = MaterialTheme.typography.labelLarge)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text(first!!.name, modifier = Modifier.weight(1f)); Text(second!!.name, modifier = Modifier.weight(1f)) }
            val labels = (first!!.metrics + second!!.metrics).map { it.first }.distinct()
            labels.forEach { label -> Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text("$label: ${first!!.metrics.firstOrNull { it.first == label }?.second ?: "-"}", modifier = Modifier.weight(1f)); Text(second!!.metrics.firstOrNull { it.first == label }?.second ?: "-", modifier = Modifier.weight(1f)) } }
        }
    }
}

@androidx.compose.runtime.Composable
private fun StyleChoice(label: String, selected: BeerStyle?, styles: List<BeerStyle>, onSelect: (BeerStyle) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box { Button(onClick = { open = true }) { Text(selected?.let { "$label: ${it.number} ${it.name}" } ?: "Choose $label") }; DropdownMenu(open, { open = false }) { styles.take(100).forEach { style -> DropdownMenuItem(text = { Text("${style.number} ${style.name}") }, onClick = { onSelect(style); open = false }) } } }
}

@OptIn(ExperimentalMaterial3Api::class)
@androidx.compose.runtime.Composable
private fun CategoryDetail(category: StyleCategory, onBack: () -> Unit, onOpen: (BeerStyle) -> Unit) {
    Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
        TopAppBar(title = { Text(if (category.number.isBlank()) categoryDisplay(category.name) else "${category.number} ${categoryDisplay(category.name)}") }, navigationIcon = { TextButton(onClick = onBack) { Text("Back") } })
        LazyColumn(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(category.styles, key = { it.id }) { style ->
                Card(onClick = { onOpen(style) }, modifier = Modifier.fillMaxWidth()) { Column(Modifier.padding(14.dp)) { Text("${style.number} ${display(style.name)}", style = MaterialTheme.typography.titleMedium); if (style.metrics.isNotEmpty()) Text(style.metrics.take(2).joinToString("  •  ") { "${it.first}: ${it.second}" }, style = MaterialTheme.typography.bodySmall) } }
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun StyleDetail(style: BeerStyle, favourite: Boolean = false, onFavourite: () -> Unit = {}, onBack: () -> Unit) {
    Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text("${style.number} ${display(style.name)}", style = MaterialTheme.typography.headlineSmall); Row { TextButton(onClick = onFavourite) { Text(if (favourite) "★" else "☆") }; Button(onClick = onBack) { Text("Back") } } }
        Text(display(style.category), style = MaterialTheme.typography.titleMedium)
        style.metrics.forEach { (label, value) -> Text("$label: $value") }
        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) { items(style.sections) { (title, body) -> Column { Text(title, style = MaterialTheme.typography.titleMedium); Text(body) } } }
    }
}
