<script setup lang="ts">
import { ref } from 'vue'
import MapCanvas from '@shared/ui/map-canvas'
import type { MapCanvasExpose } from '@shared/ui/map-canvas/public'
import { normalizeZone } from './adapters/normalize-zone'
import { fetchHarborZones } from './services/harbor-api'
import type { HarborMapExpose, HarborZoneResult } from './types'

withDefaults(
  defineProps<{
    initialZoom?: number
  }>(),
  {
    initialZoom: 12,
  },
)

const emit = defineEmits<{
  zoneStatusChange: [status: 'visible' | 'hidden' | 'error']
}>()

const mapCanvasRef = ref<MapCanvasExpose>()
let requestVersion = 0

async function setZonesVisible(visible: boolean): Promise<HarborZoneResult> {
  const currentVersion = ++requestVersion
  const mapCanvas = mapCanvasRef.value
  if (!mapCanvas) return { status: 'render-error' }

  if (!visible) {
    try {
      await mapCanvas.clearZones()
      if (currentVersion !== requestVersion) return { status: 'superseded' }
      emit('zoneStatusChange', 'hidden')
      return { status: 'success', count: 0 }
    } catch {
      emit('zoneStatusChange', 'error')
      return { status: 'render-error' }
    }
  }

  try {
    const response = await fetchHarborZones()
    if (currentVersion !== requestVersion) return { status: 'superseded' }
    if (response.code !== 200) {
      emit('zoneStatusChange', 'error')
      return { status: 'request-error' }
    }

    const zones = response.data.map(normalizeZone).filter((zone) => zone !== null)
    if (zones.length === 0) return { status: 'empty' }

    const result = await mapCanvas.replaceZones(zones)
    if (currentVersion !== requestVersion) return { status: 'superseded' }
    if (result.status !== 'success') {
      emit('zoneStatusChange', 'error')
      return { status: result.status === 'empty' ? 'empty' : 'render-error' }
    }

    emit('zoneStatusChange', 'visible')
    return { status: 'success', count: result.count }
  } catch {
    if (currentVersion !== requestVersion) return { status: 'superseded' }
    emit('zoneStatusChange', 'error')
    return { status: 'request-error' }
  }
}

defineExpose<HarborMapExpose>({ setZonesVisible })
</script>

<template>
  <section class="harbor-map">
    <slot name="toolbar" />
    <MapCanvas ref="mapCanvasRef" :initial-zoom="initialZoom" />
  </section>
</template>
