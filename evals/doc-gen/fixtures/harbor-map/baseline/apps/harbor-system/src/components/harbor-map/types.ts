export interface HarborZoneDto {
  zone_id: string
  enabled: '0' | '1'
  points: string
}

export type HarborZoneResult =
  | { status: 'success'; count: number }
  | { status: 'empty' }
  | { status: 'request-error' }
  | { status: 'render-error' }
  | { status: 'superseded' }

export interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
