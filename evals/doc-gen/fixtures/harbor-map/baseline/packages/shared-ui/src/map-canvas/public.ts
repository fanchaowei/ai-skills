export interface MapZoneModel {
  id: string
  coordinates: Array<[number, number]>
}

export type MapZoneCommandResult =
  | { status: 'success'; count: number }
  | { status: 'empty' }
  | { status: 'render-error' }

export interface MapCanvasExpose {
  replaceZones(zones: MapZoneModel[]): Promise<MapZoneCommandResult>
  clearZones(): Promise<void>
}
