# Implementation of the Diamond Square algorithm for random terrain generation in Julia
#
# To keep the math simple, the terrain will have side lengths that are a power of two, plus 1.
#
# To make sure the terrain can be cleanly tiled, the last row and last column are the same as the first row and the
# first column, respectively. Using the wrap_index function, code can access any point in the underlying array as
# though the terrain was an infinite plane, and the wrap_index function will translate that into the correct x, y
# coordinates for the underlying array.

dec_div_inc(n) = ((n - 1) / 2) + 1

function make_terrain_walk(grid_size)
    # For a given terrain size, produce a path that visits every point in the terrain in the correct order for
    # generating random terrain for the diamond-square algorithm.
    # This implementation assumes that the terrain grid doesn't share points between the first row and last row,
    # or first column and last column. Those can be filtered out later.
    if !is_power_of_two(grid_size - 1)
        throw(ArgumentError("grid_size must be equal to a power of two, plus 1"))
    end

    points = (String, Int64, Int64)[]
    iteration_size = grid_size
    # For each level of iteration, do all the square step points, then do all the diamond step points.
    while iteration_size >= 3
        next_squares = get_square_points(iteration_size, grid_size)
        for point in next_squares
            push!(points, ("square", point[1], point[2]))
        end
        next_diamonds = get_diamond_points(iteration_size, grid_size)
        for point in next_diamonds
            push!(points, ("diamond", point[1], point[2]))
        end
        iteration_size = ((iteration_size - 1) / 2) + 1
    end

    return points
end

function get_square_points(rect_size, grid_size)
    # For a given point, produce a list of the points that make up the next iteration of squares
    new_points = (Int64, Int64)[]
    half_rect = (rect_size - 1) / 2
    for x = 1:rect_size-1:grid_size-1
        for y = 1:rect_size-1:grid_size-1
            push!(new_points, (x + half_rect, y + half_rect))
        end
    end
    return new_points
end

function get_diamond_points(rect_size, grid_size)
    # For a given point, produce a list of the points that make up the next iteration of diamonds
    new_points = (Int64, Int64)[]
    half_rect = (rect_size - 1) / 2
    wrap_func(n) = wrap_index(n, grid_size)
    for x = 1:rect_size-1:grid_size-1
        for y = 1:rect_size-1:grid_size-1
            push_unique!(new_points, (wrap_func(x), wrap_func(y + half_rect)))
            push_unique!(new_points, (wrap_func(x + half_rect), wrap_func(y + (rect_size - 1))))
            push_unique!(new_points, (wrap_func(x + (rect_size - 1)), wrap_func(y + half_rect)))
            push_unique!(new_points, (wrap_func(x + half_rect), wrap_func(y)))
        end
    end
    return new_points
end

function push_unique!(arr, val)
    # Pushes a value, val, on to the end of an array, arr, if val is not already in arr.
    # Currently uses a linear search since its easy to implement.
    for test_point in arr
        if test_point == val
            return
        end
    end

    push!(arr, val)
end

function diamond(tA, point)
    # Given a point in a terrain array, find the 4 surrounding points for the diamond step
    grid_size = size(tA, 1) + 1
    i = neighbour_indices(point, grid_size)
    # println("I: $offset $grid_size $top $bottom $left $right")
    return [tA[i["top"], point[2]], tA[point[1], i["right"]], tA[i["bottom"], point[2]], tA[point[1], i["left"]]]
end

function corners(tA, point)
    # Given a point in a terrain array, find the "corners" of the square step for this point
    grid_size = size(tA, 1) + 1
    i = neighbour_indices(point, grid_size)
    # println("I: $offset $grid_size $top $bottom $left $right")
    return [tA[i["top"], i["left"]], tA[i["top"], i["right"]], tA[i["bottom"], i["right"]], tA[i["bottom"], i["left"]]]
end

function neighbour_indices(point, grid_size)
    # For diamond or square steps, the indices for the top, bottom, left, and right are calculated the same.
    offset = two_power(point[1]-1)
    return ["top" => wrap_index(point[1] - offset, grid_size),
            "bottom" => wrap_index(point[1] + offset, grid_size),
            "left" => wrap_index(point[2] - offset, grid_size),
            "right" => wrap_index(point[2] + offset, grid_size)]
end

function wrap_index(index, grid_size)
    # The trick about the terrain array is that the last row and last column are duplicates of the first row and column.
    # Wrap index hides this abstraction, and let us wrap around to look up values from the other side.
    size_less_one = grid_size - 1
    if 0 <= index
        mod_index = index % size_less_one
        return mod_index != 0 ? mod_index : size_less_one
    else
        return (index % size_less_one) + size_less_one
    end
end

function two_power(p)
    # Find the largest power of two (pow) and multiple (n) such that pow*n = p
    if is_power_of_two(p)
        return p
    end

    trial_pow = two_power_less_than(p)
    while p % trial_pow != 0
        trial_pow = two_power_less_than(trial_pow)
    end

    return trial_pow
end

function two_power_less_than(n)
    # Find the largest power of two that is smaller than n
    if n <= 1
        return n
    end

    pow = 1
    while pow < n
        pow *= 2
    end
    return pow / 2
end

is_power_of_two(n) = n & (n - 1) == 0

function show_usage()
    println("Usage: jterrain [terrain_size], with terrain_size == a power of two, plus 1")
    exit()
end

function main()
    if length(ARGS) != 1
        show_usage()
    end

    grid_size = int64(ARGS[1])

    if !is_power_of_two(grid_size-1)
        show_usage()
    end

    terrain = [0.0 for x=1:grid_size-1, y=1:grid_size-1]

    for p in make_terrain_walk(grid_size)
        noise = rand() * 0.25
        terrain[p[2:3]...] = mean(p[1] == "square" ? corners(terrain, (p[2:3])) : diamond(terrain, (p[2:3]))) + noise
    end

    wrap_grid(n) = wrap_index(n, grid_size)

    open("out.obj", "w") do f
        for x in 1:grid_size
            for y in 1:grid_size
                write(f, "v $(float64(x)) $(float64(y)) $(terrain[wrap_grid(x), wrap_grid(y)])\n")
            end
        end

        for x in 1:grid_size-1
            for y in 1:grid_size-1
                top_left = x + (grid_size*(y-1))
                bottom_left = top_left + grid_size
                top_right = top_left + 1
                bottom_right = bottom_left + 1
                write(f, "f $top_left// $bottom_left// $top_right//\n")
                write(f, "f $top_right// $bottom_left// $bottom_right//\n")
            end
        end
    end
end

main()
