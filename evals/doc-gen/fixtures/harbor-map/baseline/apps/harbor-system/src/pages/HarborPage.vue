<script setup lang="ts">
import { ref } from 'vue'
import HarborMap from '../components/harbor-map/HarborMap.vue'
import type { HarborMapExpose } from '../components/harbor-map/types'

const harborMapRef = ref<HarborMapExpose>()
const zonesChecked = ref(false)

async function handleZonesToggle(checked: boolean): Promise<void> {
  const result = await harborMapRef.value?.setZonesVisible(checked)
  zonesChecked.value = result?.status === 'success' ? checked : false
}
</script>

<template>
  <label>
    <input
      type="checkbox"
      :checked="zonesChecked"
      @change="handleZonesToggle(($event.target as HTMLInputElement).checked)"
    />
    Harbor zones
  </label>
  <HarborMap ref="harborMapRef" />
</template>
