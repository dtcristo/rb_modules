import('math_tools/basic') => { add:, PI: pi }
PI = pi

def circle_area(radius)
  PI * (radius**2)
end

export(
  circle_area: method(:circle_area),
  version: '2.0.0',
  add:, # Re-exporting the imported add function
)
