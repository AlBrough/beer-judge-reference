import { createHash } from 'node:crypto'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { load } from 'cheerio'

const root = new URL('../', import.meta.url)
const resourcesDirectory = new URL('Resources/', root)
const bjcpSource = 'https://raw.githubusercontent.com/BrewVault/bjcp-json/main/data.json'
const aabcSource = 'https://raw.githubusercontent.com/BrewVault/aabc2025-json/main/data.json'
const baSource = 'https://www.brewersassociation.org/edu/brewers-association-beer-style-guidelines/'

await mkdir(resourcesDirectory, { recursive: true })

const [bjcpStyles, aabcInput, baHTML] = await Promise.all([
  fetchJSON(bjcpSource),
  loadAABCInput(),
  fetchText(baSource),
])

const bjcp = {
  schemaVersion: 1,
  providerID: 'bjcp',
  providerName: 'BJCP',
  edition: '2021',
  title: '2021 BJCP Beer Style Guidelines',
  sourceURL: 'https://www.bjcp.org/bjcp-style-guidelines/',
  attribution: '2021 Beer Judge Certification Program Beer Style Guidelines.',
  styles: bjcpStyles.map(normaliseBJCPStyle),
}

const ba = {
  schemaVersion: 1,
  providerID: 'ba',
  providerName: 'Brewers Association',
  edition: '2026',
  title: '2026 Brewers Association Beer Style Guidelines',
  sourceURL: baSource,
  attribution: 'Brewers Association 2026 Beer Style Guidelines (https://www.brewersassociation.org/edu/brewers-association-beer-style-guidelines/) published by the Brewers Association.',
  styles: parseBAStyles(baHTML),
}

const aabc = {
  schemaVersion: 1,
  providerID: 'aabc',
  providerName: 'AABC',
  edition: '2025',
  title: 'AABC 2025 Style Guidelines',
  sourceURL: 'https://aabc.org.au/',
  attribution: 'AABC 2025 Categories, compiling the BJCP 2021 Beer, BJCP 2015 Mead and BJCP 2025 Cider style guidelines.',
  styles: aabcInput.normalised ? aabcInput.styles : normaliseAABCDataset(aabcInput.styles),
}

if (bjcp.styles.length < 120) throw new Error(`BJCP import unexpectedly produced ${bjcp.styles.length} styles`)
if (aabc.styles.length !== 152) throw new Error(`AABC import unexpectedly produced ${aabc.styles.length} styles`)
if (ba.styles.length < 100) throw new Error(`BA import unexpectedly produced ${ba.styles.length} styles`)

const datasets = [
  await writeDataset('bjcp-2021.json', bjcp),
  await writeDataset('aabc-2025.json', aabc),
  await writeDataset('ba-2026.json', ba),
]

const previousManifest = await readPreviousManifest()
const unchanged = previousManifest?.datasets?.length === datasets.length && datasets.every(({ dataset, sha256 }) =>
  previousManifest.datasets.some((item) => item.id === `${dataset.providerID}-${dataset.edition}` && item.sha256 === sha256))
const manifest = {
  schemaVersion: 1,
  publishedAt: unchanged ? previousManifest.publishedAt : new Date().toISOString(),
  datasets: datasets.map(({ file, dataset, sha256 }) => ({
    id: `${dataset.providerID}-${dataset.edition}`,
    providerID: dataset.providerID,
    providerName: dataset.providerName,
    edition: dataset.edition,
    title: dataset.title,
    localResource: file.replace(/\.json$/, ''),
    remoteURL: `https://raw.githubusercontent.com/AlBrough/beer-judge-reference/main/Resources/${file}`,
    sha256,
    attribution: dataset.attribution,
    sourceURL: dataset.sourceURL,
  })),
}

await writeFile(new URL('guidelines-manifest.json', resourcesDirectory), `${JSON.stringify(manifest, null, 2)}\n`)
console.log(`BJCP ${bjcp.edition}: ${bjcp.styles.length} styles`)
console.log(`AABC ${aabc.edition}: ${aabc.styles.length} styles`)
console.log(`BA ${ba.edition}: ${ba.styles.length} styles`)

function normaliseBJCPStyle(style) {
  const sections = [
    ['Overall impression', style.overallimpression],
    ['Aroma', style.aroma],
    ['Appearance', style.appearance],
    ['Flavor', style.flavor],
    ['Mouthfeel', style.mouthfeel],
    ['Comments', style.comments],
    ['Entry instructions', style.entryinstructions],
    ['History', style.history],
    ['Characteristic ingredients', style.characteristicingredients],
    ['Style comparison', style.stylecomparison],
    ['Commercial examples', style.commercialexamples],
  ].filter(([, value]) => meaningful(value)).map(([title, body]) => ({ title, body: clean(body) }))

  const metrics = [
    rangeMetric('IBU', style.ibumin, style.ibumax),
    rangeMetric('Original gravity', style.ogmin, style.ogmax),
    rangeMetric('Final gravity', style.fgmin, style.fgmax),
    rangeMetric('ABV', style.abvmin, style.abvmax, '%'),
    rangeMetric('SRM', style.srmmin, style.srmmax),
  ].filter(Boolean)

  return {
    id: `bjcp-${style.number}`,
    number: clean(style.number),
    name: clean(style.name),
    category: clean(style.category),
    categoryNumber: clean(style.categorynumber),
    sections,
    metrics,
    tags: String(style.tags ?? '').split(',').map(clean).filter(Boolean),
  }
}

function normaliseAABCDataset(styles) {
  const supportingRecords = new Map(
    styles.filter((style) => style.competitionentry === false).map((style) => [style.id, style]),
  )
  return styles
    .filter((style) => style.competitionentry !== false)
    .map((style, index) => normaliseAABCStyle(style, index, supportingRecords.get(style.parentstyleid)))
}

function normaliseAABCStyle(style, index, supportingRecord) {
  const sections = [
    ['Preamble', style.preamble],
    ['Overall impression', style.overallimpression],
    ['Aroma and flavor', style.aromaandflavor],
    ['Aroma', style.aroma],
    ['Appearance', style.appearance],
    ['Flavor', style.flavor],
    ['Mouthfeel', style.mouthfeel],
    ['Comments', style.comments],
    ['Entry instructions', style.entryinstructions],
    ['History', style.history],
    ['Characteristic ingredients', style.characteristicingredients],
    ['Ingredients', style.ingredients],
    ['Varieties', style.varieties],
    ['Style comparison', style.stylecomparison],
    ['Currently defined types', style.currentlydefinedtypes],
    ['Strength classifications', style.strengthclassifications],
    ['Commercial examples', style.commercialexamples],
  ].filter(([, value]) => meaningful(value)).map(([title, body]) => ({ title, body: clean(body) }))

  const metrics = [
    rangeMetric('IBU', style.ibumin, style.ibumax),
    rangeMetric('Original gravity', style.ogmin, style.ogmax),
    rangeMetric('Final gravity', style.fgmin, style.fgmax),
    rangeMetric('ABV', style.abvmin, style.abvmax, '%'),
    rangeMetric('SRM', style.srmmin, style.srmmax),
  ].filter(Boolean)

  if (meaningful(style.vitalstatistics) && metrics.length === 0) {
    sections.push({ title: 'Vital statistics', body: clean(style.vitalstatistics) })
  }
  if (supportingRecord) sections.push(...aabcSupportingSections(supportingRecord))

  const sourceTags = String(style.tags ?? '').split(',').map(clean).filter(Boolean)
  return {
    id: clean(style.id) || `aabc-${index + 1}`,
    number: clean(style.number),
    name: clean(style.name),
    category: clean(style.category),
    categoryNumber: clean(style.categorynumber),
    sortOrder: Number(style.judgingorder) || index + 1,
    sections,
    metrics,
    tags: [...new Set([clean(style.beveragetype), clean(style.sourceguideline), ...sourceTags].filter(Boolean))],
  }
}

function aabcSupportingSections(style) {
  return [
    ['Preamble', style.preamble],
    ['Overall impression', style.overallimpression],
    ['Aroma', style.aroma],
    ['Appearance', style.appearance],
    ['Flavor', style.flavor],
    ['Mouthfeel', style.mouthfeel],
    ['Comments', style.comments],
    ['Entry instructions', style.entryinstructions],
    ['Currently defined types', style.currentlydefinedtypes],
    ['Strength classifications', style.strengthclassifications],
    ['Vital statistics', style.vitalstatistics],
  ].filter(([, value]) => meaningful(value)).map(([title, body]) => ({
    title: `Specialty IPA guidance - ${title}`,
    body: clean(body),
  }))
}

function parseBAStyles(html) {
  const $ = load(html, { decodeEntities: true })
  return $('#beer-styles .beer-style').map((index, element) => {
    const style = $(element)
    const list = style.children('ul.list-with-heading').first()
    const name = clean(list.children('li').first().text())
    const group = style.closest('.beer-style-group')
    const origin = clean(group.children('h2.origin').first().text()) || 'Beer Styles'
    const family = clean(group.prevAll('h1.center-content').first().text()) || 'Beer Styles'
    const sections = []
    const metrics = []

    list.children('li').slice(1).each((_, item) => readBAField($(item), sections, metrics))
    list.children('ul.horizontal').children('li').each((_, item) => readBAField($(item), sections, metrics))

    return {
      id: `ba-${list.attr('id') || index + 1}`,
      number: '',
      name,
      category: origin,
      categoryNumber: family,
      sections,
      metrics,
      tags: [family, origin].map(clean).filter(Boolean),
    }
  }).get().filter((style) => style.name)
}

function readBAField(item, sections, metrics) {
  const strong = item.children('strong').first()
  if (!strong.length) return
  const title = clean(strong.text()).replace(/:$/, '')
  strong.remove()
  const body = clean(item.text())
  if (!body) return
  if (/Original Gravity|Final Gravity|Alcohol by Weight|Bitterness \(IBU\)|Color SRM/i.test(title)) {
    metrics.push({ label: title, value: body })
  } else {
    sections.push({ title, body })
  }
}

function rangeMetric(label, minimum, maximum, suffix = '') {
  if (!meaningful(minimum) && !meaningful(maximum)) return null
  const values = [minimum, maximum].filter(meaningful).map(clean)
  return { label, value: `${values.join(' - ')}${suffix}` }
}

function meaningful(value) {
  const cleaned = clean(value)
  return cleaned && cleaned !== '-'
}

function clean(value) {
  return String(value ?? '').replace(/\s+/g, ' ').trim()
}

async function writeDataset(file, dataset) {
  const content = `${JSON.stringify(dataset, null, 2)}\n`
  await writeFile(new URL(file, resourcesDirectory), content)
  return { file, dataset, sha256: createHash('sha256').update(content).digest('hex') }
}

async function fetchJSON(url) {
  return JSON.parse(await fetchText(url))
}

async function fetchText(url, headers = {}) {
  const response = await fetch(url, { headers: { 'user-agent': 'BeerJudgeReference-data-sync/1.0', ...headers } })
  if (!response.ok) throw new Error(`${response.status} fetching ${url}`)
  return response.text()
}

async function loadAABCInput() {
  const token = process.env.AABC_GITHUB_TOKEN
  try {
    const headers = token ? { authorization: `Bearer ${token}` } : {}
    return { styles: JSON.parse(await fetchText(aabcSource, headers)), normalised: false }
  } catch (remoteError) {
    try {
      const local = JSON.parse(await readFile(new URL('../../aabc2025-json/data.json', import.meta.url), 'utf8'))
      console.warn('AABC source is private - using the local sibling repository.')
      return { styles: local, normalised: false }
    } catch {
      try {
        const existing = JSON.parse(await readFile(new URL('aabc-2025.json', resourcesDirectory), 'utf8'))
        console.warn('AABC source is private - retaining the current validated snapshot.')
        return { styles: existing.styles, normalised: true }
      } catch {
        throw remoteError
      }
    }
  }
}

async function readPreviousManifest() {
  try {
    return JSON.parse(await readFile(new URL('guidelines-manifest.json', resourcesDirectory), 'utf8'))
  } catch {
    return null
  }
}
