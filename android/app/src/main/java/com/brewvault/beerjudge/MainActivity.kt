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
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
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

private fun display(value: String): String = value
    .replace(Regex("\\bipa\\b", RegexOption.IGNORE_CASE), "IPA")
    .replace(Regex("\\s*[â€“â€”-]\\s*"), " - ")

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

private val JudgeLightColors = lightColorScheme(primary = Color(0xFF6849A6), onPrimary = Color.White, surface = Color(0xFFFFF7FF), background = Color(0xFFFFF7FF), surfaceVariant = Color(0xFFE9E1EB))
private val JudgeDarkColors = darkColorScheme(primary = Color(0xFFD0BCFF), onPrimary = Color(0xFF382060), surface = Color(0xFF151218), background = Color(0xFF151218), surfaceVariant = Color(0xFF49454F))

@OptIn(ExperimentalMaterial3Api::class)
@androidx.compose.runtime.Composable
private fun BeerJudgeApp(activity: ComponentActivity) {
    val editions = listOf("BJCP 2021" to "bjcp-2021.json", "AABC 2025" to "aabc-2025.json", "BA 2026" to "ba-2026.json")
    var selected by remember { mutableStateOf(editions.first()) }
    var styles by remember(selected) { mutableStateOf(readStyles(activity, selected.second)) }
    var query by remember { mutableStateOf("") }
    var opened by remember { mutableStateOf<BeerStyle?>(null) }
    var aabcKind by rememberSaveable { mutableStateOf("Beer") }
    var appearance by rememberSaveable { mutableStateOf(activity.getPreferences(0).getString("appearance", Appearance.SYSTEM.name) ?: Appearance.SYSTEM.name) }
    LaunchedEffect(appearance) { activity.getPreferences(0).edit().putString("appearance", appearance).apply() }
    val selectedAppearance = Appearance.values().firstOrNull { it.name == appearance } ?: Appearance.SYSTEM
    val dark = when (selectedAppearance) { Appearance.SYSTEM -> isSystemInDarkTheme(); Appearance.LIGHT -> false; Appearance.DARK -> true }
    val kindFiltered = if (selected.first.startsWith("AABC")) styles.filter { when (aabcKind) { "Mead" -> it.category.equals("MEAD", true); "Cider" -> it.category.equals("CIDER", true); else -> !it.category.equals("MEAD", true) && !it.category.equals("CIDER", true) } } else styles
    val filtered = sortedStyles(kindFiltered.filter { query.isBlank() || listOf(it.number, it.name, it.category).joinToString(" ").contains(query, ignoreCase = true) })

    MaterialTheme(colorScheme = if (dark) JudgeDarkColors else JudgeLightColors) {
        Surface(Modifier.fillMaxSize()) {
            if (opened != null) StyleDetail(opened!!) { opened = null } else {
                var menuOpen by remember { mutableStateOf(false) }
                var themeOpen by remember { mutableStateOf(false) }
                Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
                    TopAppBar(title = { Text("Beer Judge Reference") }, actions = {
                        Box {
                            TextButton(onClick = { themeOpen = true }) { Text("Theme") }
                            DropdownMenu(expanded = themeOpen, onDismissRequest = { themeOpen = false }) {
                                Appearance.values().forEach { option -> DropdownMenuItem(text = { Text(option.label) }, onClick = { appearance = option.name; themeOpen = false }) }
                            }
                        }
                    })
                    Column(Modifier.padding(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Box {
                            Button(onClick = { menuOpen = true }) { Text(selected.first) }
                            DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                                editions.forEach { edition -> DropdownMenuItem(text = { Text(edition.first) }, onClick = { selected = edition; styles = readStyles(activity, edition.second); menuOpen = false; query = "" }) }
                            }
                        }
                        if (selected.first.startsWith("AABC")) {
                            var kindOpen by remember { mutableStateOf(false) }
                            Box {
                                Button(onClick = { kindOpen = true }) { Text("AABC: $aabcKind") }
                                DropdownMenu(expanded = kindOpen, onDismissRequest = { kindOpen = false }) {
                                    listOf("Beer", "Mead", "Cider").forEach { kind -> DropdownMenuItem(text = { Text(kind) }, onClick = { aabcKind = kind; kindOpen = false; query = "" }) }
                                }
                            }
                        }
                        OutlinedTextField(value = query, onValueChange = { query = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Search styles") }, singleLine = true)
                        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            items(filtered, key = { it.id }) { style ->
                                Card(onClick = { opened = style }, modifier = Modifier.fillMaxWidth()) {
                                    Column(Modifier.padding(14.dp)) {
                                        Text("${style.number} ${display(style.name)}", style = MaterialTheme.typography.titleMedium)
                                        Text(display(style.category), style = MaterialTheme.typography.bodyMedium)
                                        if (style.metrics.isNotEmpty()) Text(style.metrics.take(2).joinToString("  •  ") { "${it.first}: ${it.second}" }, style = MaterialTheme.typography.bodySmall)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun StyleDetail(style: BeerStyle, onBack: () -> Unit) {
    Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text("${style.number} ${display(style.name)}", style = MaterialTheme.typography.headlineSmall); Button(onClick = onBack) { Text("Back") } }
        Text(display(style.category), style = MaterialTheme.typography.titleMedium)
        style.metrics.forEach { (label, value) -> Text("$label: $value") }
        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) { items(style.sections) { (title, body) -> Column { Text(title, style = MaterialTheme.typography.titleMedium); Text(body) } } }
    }
}
