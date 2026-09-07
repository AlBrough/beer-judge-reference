package com.brewvault.bjr

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.json.JSONObject

data class BeerStyle(val id: String, val number: String, val name: String, val category: String, val metrics: List<Pair<String, String>>, val sections: List<Pair<String, String>>)

private fun display(value: String): String = value
    .replace(Regex("\\bipa\\b", RegexOption.IGNORE_CASE), "IPA")
    .replace(Regex("\\s*[–—-]\\s*"), " - ")

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
        BeerStyle(item.optString("id"), item.optString("number"), item.optString("name"), item.optString("category"), metrics, sections)
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { BeerJudgeApp(this) }
    }
}

@androidx.compose.runtime.Composable
private fun BeerJudgeApp(activity: ComponentActivity) {
    val editions = listOf("BJCP 2021" to "bjcp-2021.json", "AABC 2025" to "aabc-2025.json", "BA 2026" to "ba-2026.json")
    var selected by remember { mutableStateOf(editions.first()) }
    var styles by remember(selected) { mutableStateOf(readStyles(activity, selected.second)) }
    var query by remember { mutableStateOf("") }
    var opened by remember { mutableStateOf<BeerStyle?>(null) }
    val filtered = styles.filter { query.isBlank() || listOf(it.number, it.name, it.category).joinToString(" ").contains(query, ignoreCase = true) }

    MaterialTheme {
        Surface(Modifier.fillMaxSize()) {
            if (opened != null) {
                StyleDetail(opened!!) { opened = null }
            } else {
                Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Beer Judge Reference", style = MaterialTheme.typography.headlineMedium)
                    var menuOpen by remember { mutableStateOf(false) }
                    Button(onClick = { menuOpen = true }) { Text(selected.first) }
                    DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                        editions.forEach { edition -> DropdownMenuItem(text = { Text(edition.first) }, onClick = { selected = edition; styles = readStyles(activity, edition.second); menuOpen = false; query = "" }) }
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

@androidx.compose.runtime.Composable
private fun StyleDetail(style: BeerStyle, onBack: () -> Unit) {
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("${style.number} ${display(style.name)}", style = MaterialTheme.typography.headlineSmall)
            Button(onClick = onBack) { Text("Back") }
        }
        Text(display(style.category), style = MaterialTheme.typography.titleMedium)
        style.metrics.forEach { (label, value) -> Text("$label: $value") }
        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) { items(style.sections) { (title, body) ->
            Column { Text(title, style = MaterialTheme.typography.titleMedium); Text(body) }
        } }
    }
}
