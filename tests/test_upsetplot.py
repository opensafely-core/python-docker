from upsetplot import generate_counts, plot


def test_upsetplot():
    # just tests that we can use upsetplot functions without error
    # generate some sample data
    example = generate_counts()
    # create plots with upsetplot
    pt = plot(example)  
    assert isinstance(pt, dict)
    assert sorted(pt.keys()) == ["intersections", "matrix", "shading", "totals"]
 