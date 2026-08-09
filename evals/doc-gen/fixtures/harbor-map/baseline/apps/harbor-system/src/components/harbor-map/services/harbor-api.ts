import type { HarborZoneDto } from '../types'

export interface HarborApiResponse {
  code: number
  data: HarborZoneDto[]
}

export async function fetchHarborZones(): Promise<HarborApiResponse> {
  return { code: 200, data: [] }
}
