import type { MapZoneModel } from '@shared/ui/map-canvas/public'
import type { HarborZoneDto } from '../types'

export function normalizeZone(dto: HarborZoneDto): MapZoneModel | null {
  if (dto.enabled !== '0' || dto.zone_id.trim() === '') return null

  const coordinates = dto.points
    .split('_')
    .map((point) => point.split(',').map(Number))
    .filter(
      (point): point is [number, number] =>
        point.length === 2 && Number.isFinite(point[0]) && Number.isFinite(point[1]),
    )

  if (coordinates.length < 3) return null
  return { id: dto.zone_id, coordinates }
}
