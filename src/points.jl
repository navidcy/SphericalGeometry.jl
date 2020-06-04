export midpoint, intermediate_point, destination_point, intersection_point,
intersection_points

"""
    midpoint(point₁::Point, point₂::Point)

Return the half-way point `midpoint` [deg] on the great circle line between
the positions `point₁` and `point₂` [deg] on a unit sphere.

Source: www.movable-type.co.uk/scripts/latlong.html
"""
function midpoint(point₁::Point, point₂::Point)
    Δpos = point₂ - point₁
    Bx = cosd(point₂.ϕ) * cosd(Δpos.λ)
    By = cosd(point₂.ϕ) * sind(Δpos.λ)
    ϕₘ = atand(sind(point₁.ϕ) + sind(point₂.ϕ), √((cosd(point₁.ϕ) + Bx)^2 + By^2))
    λₘ = point₁.λ + atand(By, cosd(point₁.ϕ) + Bx)
    return Point(ϕₘ, normalize(λₘ, -180.0, 180.0))
end

"""
    midpoint(arc::Arc)

Return the half-way point `midpoint` [deg] on the great circle `arc`
[deg] on a unit sphere.
"""
midpoint(arc::Arc) = midpoint(arc.point₁,
arc.point₂)

"""
    midpoint(arcs::Arcs)

Return the half-way point `midpoint` [deg] on the great circle `arcs`
[deg] on a unit sphere.
"""
midpoint(arcs::Arcs) = intermediate_point(arcs, 0.5)

"""
    intermediate_point(point₁::Point, point₂::Point, fraction::Float64)

Return the `intermediate_point` [deg] at any `fraction` along the great circle
line section between the two points `point₁` and `point₂` [deg]. The fraction
along the great circle line section is such that `fraction` = 0.0 is at `point₁`
[deg] and `fraction` 1.0 is at `point₂` [deg].

Source: www.movable-type.co.uk/scripts/latlong.html
"""
function intermediate_point(point₁::Point, point₂::Point, fraction::Float64)
    δ = angular_distance(point₁, point₂)
    a = sind((1.0 - fraction) * δ) / sind(δ)
    b = sind(fraction * δ) / sind(δ)
    x = a * cosd(point₁.ϕ) * cosd(point₁.λ) + b * cosd(point₂.ϕ) * cosd(point₂.λ)
    y = a * cosd(point₁.ϕ) * sind(point₁.λ) + b * cosd(point₂.ϕ) * sind(point₂.λ)
    z = a * sind(point₁.ϕ) + b * sind(point₂.ϕ)
    ϕᵢ = atand(z, √(x*x + y*y))
    λᵢ = atand(y, x)
    return Point(ϕᵢ, λᵢ)
end

"""
    intermediate_point(arc::Arc, fraction::Float64)

Return the `intermediate_point` [deg] at any `fraction` along the great circle
`arc` [deg]. The fraction along the great circle `arc` is such
that `fraction` = 0.0 is at the start of the `arc` and `fraction` 1.0 is
at the end of the `arc`.
"""
intermediate_point(arc::Arc, fraction::Float64) =
intermediate_point(arc.point₁, arc.point₂, fraction)

"""
    intermediate_point(arcs::Arcs, fraction::Float64)

Return the `intermediate_point` [deg] at any `fraction` along the great circle
`arcs` [deg]. The fraction along the great circle `arcs` is such
that `fraction` = 0.0 is at the start of the `arcs` and `fraction` 1.0 is
at the end of the `arcs`.
"""
function intermediate_point(arcs::Arcs, fraction::Float64)
    angular_length_ip = angular_length(arcs) * fraction
    p₁ = arcs.points[1]
    dist = 0.0
    if angular_length_ip == dist
        return arcs.points[1]
    end
    for p₂ in arcs.points[2:end]
        dist_p₁p₂ = angular_distance(p₁, p₂)
        if dist + dist_p₁p₂ ≥ angular_length_ip
            fraction_section = (angular_length_ip - dist) / dist_p₁p₂
            return intermediate_point(p₁, p₂, fraction_section)
        end
        dist += dist_p₁p₂
        p₁ = p₂
    end
    return arcs.points[end]
end

"""
    destination_point(start_point::Point, angular_distance::Float64,
    bearing::Float64)

Given a `start_point` [deg], initial `bearing` (clockwise from North) [deg],
`angular_distance` [deg] calculate the position of the `destina­tion_point`
[deg] traversing along a great circle line.

Source: www.movable-type.co.uk/scripts/latlong.html
"""
function destination_point(start_point::Point, angular_distance::Float64,
bearing::Float64)
    ϕ₂ = asind(sind(start_point.ϕ) * cosd(angular_distance) +
    cosd(start_point.ϕ) * sind(angular_distance) * cosd(bearing))
    λ₂ = start_point.λ + atand(sind(bearing) * sind(angular_distance) *
    cosd(start_point.ϕ), cosd(angular_distance) - sind(start_point.ϕ) * sind(ϕ₂))
    return Point(ϕ₂, λ₂)
end

"""
    destination_point(line::Line, angular_distance::Float64)

Given a line with a start_point and bearing, calculate the `destina­tion_point`
[deg] at the `angular_distance`.
"""
destination_point(line::Line, angular_distance::Float64) =
destination_point(line.point, angular_distance, line.bearing)

"""
    intersection_point(point₁::Point, point₂::Point, bearing₁₃::Float64,
    bearing₂₃::Float64)

Return the intersection point `point₃` [deg] of two great circle lines given
by two start points [deg] `point₁` and `point₂` [deg] and two bearings [deg]
from `point₁` to `point₃` [deg], and from `point₂` to `point₃` [deg].

Under certain circumstances the results can be an ∞ or *ambiguous solution*.

Source: edwilliams.org/avform.htm
"""
function intersection_point(point₁::Point, point₂::Point, bearing₁₃::Float64,
bearing₂₃::Float64)
    Δpos = point₂ - point₁
    δ₁₂ = 2asind(√(sind(Δpos.ϕ / 2)^2 + cosd(point₁.ϕ) * cosd(point₂.ϕ) * sind(Δpos.λ/2)^2))
    if sind(δ₁₂) * cosd(point₁.ϕ) == 0.0 || sind(δ₁₂) * cosd(point₂.ϕ) == 0.0
        return Point(NaN, NaN)
    end
    θₐ = acosd((sind(point₂.ϕ) - sind(point₁.ϕ) * cosd(δ₁₂)) / (sind(δ₁₂) * cosd(point₁.ϕ)))
    θᵦ = acosd((sind(point₁.ϕ) - sind(point₂.ϕ) * cosd(δ₁₂)) / (sind(δ₁₂) * cosd(point₂.ϕ)))
    local θ₁₂, θ₂₁
    if sind(Δpos.λ) > 0.0
        θ₁₂ = θₐ
        θ₂₁ = 360.0 - θᵦ
    else
        θ₁₂ = 360.0 - θₐ
        θ₂₁ = θᵦ
    end
    α₁ = (bearing₁₃ - θ₁₂ + 180.0)%(360.0) - 180.0
    α₂ = (θ₂₁ - bearing₂₃ + 180.0)%(360.0) - 180.0

    if sind(α₁) ≈ 0.0 && sind(α₂) ≈ 0.0
        return Point(Inf, Inf)  # infinity of intersections
    elseif sind(α₁) * sind(α₂) < 0.0
        # return Point_rad(Inf, Inf)  # intersection ambiguous
        return Point(NaN, NaN)
    else
        α₃ = acosd(-cosd(α₁) * cosd(α₂) + sind(α₁) * sind(α₂) * cosd(δ₁₂))
        δ₁₃ = atand(sind(δ₁₂) * sind(α₁) * sind(α₂), cosd(α₂) + cosd(α₁) * cosd(α₃))
        ϕ₃ = asind(sind(point₁.ϕ) * cosd(δ₁₃) + cosd(point₁.ϕ) * sind(δ₁₃) * cosd(bearing₁₃))
        Δλ₁₃ = atand(sind(bearing₁₃) * sind(δ₁₃) * cosd(point₁.ϕ), cosd(δ₁₃)
        - sind(point₁.ϕ) * sind(ϕ₃))
        λ₃ = point₁.λ + Δλ₁₃
        return Point(ϕ₃, λ₃)
    end
end

"""
    intersection_point(line₁::Line, line₂::Line)

Return the intersection point `point₃` [deg] of two great circle lines 'line₁'
and `line₂`.

Under certain circumstances the results can be an ∞ or *ambiguous solution*.
"""
intersection_point(line₁::Line, line₂::Line) = intersection_point(line₁.point,
line₂.point, line₁.bearing, line₂.bearing)

"""
    intersection_point(point₁::Point, point₂::Point, point₃::Point, point₄::Point)

Return the intersection `point` [deg] of two great circle line section given
by two sets of two points: `point₁` and `point₂` [deg] and `point₃` and
`point₄` [deg].

Under certain circumstances the results can be an ∞ or *ambiguous solution*.
"""
function intersection_point(point₁::Point, point₂::Point, point₃::Point,
    point₄::Point)
    inter_pnt = intersection_point(point₁, point₃, bearing(point₁, point₂),
    bearing(point₃, point₄))
    if isinf(inter_pnt.ϕ)
        return inter_pnt
    elseif angular_distance(point₁, point₂) + tolerance_deg ≥ angular_distance(point₁, inter_pnt) &&
        angular_distance(point₃, point₄) + tolerance_deg ≥ angular_distance(point₃, inter_pnt)
        return inter_pnt
    else
        return Point(NaN, NaN)
    end
end

"""
    intersection_point(arc₁::Arc, arc₂::Arc)

Return the intersection `point` [deg] of two great circle line sections.

Under certain circumstances the results can be an ∞ or *ambiguous solution*.
"""
intersection_point(arc₁::Arc, arc₂::Arc) =
intersection_point(arc₁.point₁, arc₁.point₂,
arc₂.point₁, arc₂.point₂)

#TODO Special cases for two lines overlapping.
"""
    intersection_points(arcs₁::Arcs, arcs₂::Arcs)

Return the intersection points [deg] of two line sections.
"""
function intersection_points(arcs₁::Arcs, arcs₂::Arcs)
    lss₁_p₁ = arcs₁.points[1]
    inter_points = Vector{Point{Float64}}()
    for lss₁_p₂ in arcs₁.points[2:end]
        lss₂_p₁ = arcs₂.points[1]
        distances_section = Vector{Float64}()
        inter_points_section = Vector{Point{Float64}}()
        for lss₂_p₂ in arcs₂.points[2:end]
            intersection_pnt = intersection_point(lss₁_p₁, lss₁_p₂, lss₂_p₁, lss₂_p₂)
            if isinf(intersection_pnt.ϕ) || isnan(intersection_pnt.ϕ)
                #
            else
                append!(distances_section,
                angular_distance(lss₁_p₁, intersection_pnt))
                append!(inter_points_section, [intersection_pnt])
            end
            lss₂_p₁ = lss₂_p₂
        end
        lss₁_p₁ = lss₁_p₂
        p = sortperm(distances_section)
        append!(inter_points, inter_points_section[p])
    end
    return inter_points
end

"""
    intersection_points(arcs::Arcs, polygon::Polygon)

Return the intersection points [deg] of a `arcs` with a `polygon`.
"""
intersection_points(arcs::Arcs, polygon::Polygon) =
intersection_points(arcs, Arcs(polygon.points))

"""
    intersection_points(polygon₁::Polygon, polygon₂::Polygon)

Return the intersection points [deg] of two polygons.
"""
intersection_points(polygon₁::Polygon, polygon₂::Polygon) =
intersection_points(Arcs(polygon₁.points), Arcs(polygon₂.points))
#TODO Other variants of intersection_points.