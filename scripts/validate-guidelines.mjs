import { createHash } from 'node:crypto'
import { readFile } from 'node:fs/promises'

const resources = new URL('../Resources/', import.meta.url)
const manifest = JSON.parse(await readFile(new URL('guidelines-manifest.json', resources), 'utf8'))

if (manifest.schemaVersion !== 1) throw new Error('Unsupported manifest schema')
if (!Array.isArray(manifest.datasets) || manifest.datasets.length < 2) throw new Error('Expected BJCP and BA datasets')

for (const item of manifest.datasets) {
  const content = await readFile(new URL(`${item.localResource}.json`, resources))
  const digest = createHash('sha256').update(content).digest('hex')
  if (digest !== item.sha256) throw new Error(`${item.id} checksum mismatch`)
  const dataset = JSON.parse(content)
  if (dataset.schemaVersion !== 1) throw new Error(`${item.id} has an unsupported schema`)
  if (!Array.isArray(dataset.styles) || dataset.styles.length < 100) throw new Error(`${item.id} has too few styles`)
  const ids = new Set()
  for (const style of dataset.styles) {
    if (!style.id || !style.name || !style.category) throw new Error(`${item.id} contains an incomplete style`)
    if (ids.has(style.id)) throw new Error(`${item.id} repeats style id ${style.id}`)
    ids.add(style.id)
    if (!Array.isArray(style.sections) || !Array.isArray(style.metrics)) throw new Error(`${style.id} has invalid content arrays`)
  }
  console.log(`${item.title}: ${dataset.styles.length} styles, checksum valid`)
}

