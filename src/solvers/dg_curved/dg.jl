# This method is called when a SemidiscretizationHyperbolic is constructed.
# It constructs the basic `cache` used throughout the simulation to compute
# the RHS etc.
function create_cache(mesh::CurvedMesh, equations::AbstractEquations, dg::DG, ::Any, ::Type{uEltype}) where {uEltype<:Real}
  elements = init_elements(mesh, equations, dg.basis, uEltype)

  cache = (; elements)

  return cache
end

# Extract contravariant vector Ja^i (i = index) as SVector
@inline function get_contravariant_vector(index, contravariant_vectors, indices...)

  SVector(ntuple(dim -> contravariant_vectors[index, dim, indices...], ndims(contravariant_vectors) - 3))
end


@inline function calc_boundary_flux_by_direction!(surface_flux_values, u, t, orientation,
                                                  boundary_condition::BoundaryConditionPeriodic, equations, mesh::CurvedMesh, 
                                                  dg::DG, cache, direction, node_indices, surface_node_indices, element)
  @assert isperiodic(mesh, orientation)
end


@inline function calc_boundary_flux_by_direction!(surface_flux_values, u, t, orientation,
                                                  boundary_condition, equations, mesh::CurvedMesh, dg::DG, cache,
                                                  direction, node_indices, surface_node_indices, element)
  @unpack node_coordinates, contravariant_vectors = cache.elements
  @unpack surface_flux = dg

  u_inner = get_node_vars(u, equations, dg, node_indices..., element)
  x = get_node_coords(node_coordinates, equations, dg, node_indices..., element)

  # Contravariant vector Ja^i is the normal vector
  normal = get_contravariant_vector(orientation, contravariant_vectors, node_indices..., element)
  flux = boundary_condition(u_inner, normal, direction, x, t, surface_flux, equations)

  for v in eachvariable(equations)
    surface_flux_values[v, surface_node_indices..., direction, element] = flux[v]
  end
end


@inline ndofs(mesh::CurvedMesh, dg::DG, cache) = nelements(cache.elements) * nnodes(dg)^ndims(mesh)


include("containers.jl")
include("dg_1d.jl")
include("dg_2d.jl")
include("dg_3d.jl")