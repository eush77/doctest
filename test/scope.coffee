# Variable accessible in declaration scope:
#
# > x
# "outer"
x = 'outer'

do ->
  # Variable remains accessible in inner scope:
  #
  # > x
  # "outer"
  do (x = 'inner') ->
    # Shadowed variable:
    #
    # > x
    # "inner"
