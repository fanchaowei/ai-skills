import { defineComponent, h } from 'vue'
import { mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import HarborMap from '../HarborMap.vue'
import type { HarborMapExpose } from '../types'
import { fetchHarborZones } from '../services/harbor-api'

const clearZones = vi.fn<() => Promise<void>>()
const replaceZones = vi.fn()

vi.mock('../services/harbor-api', () => ({ fetchHarborZones: vi.fn() }))

const MapCanvasStub = defineComponent({
  name: 'MapCanvas',
  setup(_, { expose }) {
    expose({ clearZones, replaceZones })
    return () => h('div', { 'data-test': 'map-canvas' })
  },
})

function mountHarborMap(options: Parameters<typeof mount>[1] = {}) {
  return mount(HarborMap, {
    ...options,
    global: {
      ...options.global,
      stubs: { MapCanvas: MapCanvasStub, ...options.global?.stubs },
    },
  })
}

describe('HarborMap', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    clearZones.mockResolvedValue()
    replaceZones.mockResolvedValue({ status: 'success', count: 1 })
  })

  it('does not request zones when hiding', async () => {
    const wrapper = mountHarborMap()
    const result = await (wrapper.vm as unknown as HarborMapExpose).setZonesVisible(false)

    expect(result).toEqual({ status: 'success', count: 0 })
    expect(fetchHarborZones).toHaveBeenCalledTimes(0)
    expect(clearZones).toHaveBeenCalledTimes(1)
  })

  it('keeps only the latest visible request result', async () => {
    const pending: Array<(value: Awaited<ReturnType<typeof fetchHarborZones>>) => void> = []
    vi.mocked(fetchHarborZones).mockImplementation(
      () => new Promise((resolve) => pending.push(resolve)),
    )
    const wrapper = mountHarborMap()
    const exposed = wrapper.vm as unknown as HarborMapExpose

    const older = exposed.setZonesVisible(true)
    const latest = exposed.setZonesVisible(true)
    pending[1]({
      code: 200,
      data: [{ zone_id: 'latest', enabled: '0', points: '1,1_2,2_3,3' }],
    })
    await Promise.resolve()
    pending[0]({
      code: 200,
      data: [{ zone_id: 'older', enabled: '0', points: '4,4_5,5_6,6' }],
    })

    await expect(latest).resolves.toEqual({ status: 'success', count: 1 })
    await expect(older).resolves.toEqual({ status: 'superseded' })
    expect(replaceZones).toHaveBeenCalledTimes(1)
  })

  it('exposes props emits slots and setZonesVisible', async () => {
    const wrapper = mountHarborMap({
      props: { initialZoom: 15 },
      slots: { toolbar: '<button data-test="toolbar">Zones</button>' },
    })

    expect(wrapper.props('initialZoom')).toBe(15)
    expect(wrapper.get('[data-test="toolbar"]').text()).toBe('Zones')
    expect(typeof (wrapper.vm as unknown as HarborMapExpose).setZonesVisible).toBe('function')

    await (wrapper.vm as unknown as HarborMapExpose).setZonesVisible(false)
    expect(wrapper.emitted('zoneStatusChange')).toEqual([['hidden']])
  })
})
