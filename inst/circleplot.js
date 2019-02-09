var diameter = 25;
var circle_margin = 4;
var stroke_width = 2;
var stroke_width_hover = 6;


    r2d3.svg.selectAll("svg > *").remove();

    var g = r2d3.svg.selectAll('task')
      .attr('height', diameter + (stroke_width_hover * 2))
      .attr('width', '90px')
      .data(data)
      .enter()
      .append('g')
      .attr('transform', function(d, i) {
                x = (i * (diameter + circle_margin)) + (diameter/2 + circle_margin);
                y = (diameter/2) + stroke_width_hover;
                return 'translate(' + x + ',' + y + ')';
              });
      g.append('text')
              .attr('fill', 'black')
              .attr('text-anchor', 'middle')
              .attr('vertical-align', 'middle')
              .attr('font-size', 8)
              .attr('y', 3)
              .text(function(d){ return d.count; });
      g.append('title').text(function(d) { return d.state + ': ' + d.count; });
      g.append('circle')
              .attr('stroke-width', function(d) {
                  if (d.count > 0)
                    return stroke_width;
                  else {
                    return 1;
                  }
              })
              .attr('stroke', function(d) {
                  if (d.count > 0)
                    return d.color;
                  else {
                    return 'grey';
                  }
              })
              .attr('fill-opacity', 0)
              .attr('r', diameter/2)
              //.attr('title', function(d) {return d.state})
              .attr('style', function(d) {
                if (d.count > 0)
                    return"cursor:pointer;"
              })
              .on('click', function(d, i) {
                  if (d.count > 0)
                    window.location = d.url;
              })
              .on('mouseover', function(d, i) {
                if (d.count > 0) {
                    d3.select(this).transition().duration(400)
                      .attr('fill-opacity', 0.3)
                      .style("stroke-width", stroke_width_hover);
                }
              })
              .on('mouseout', function(d, i) {
                if (d.count > 0) {
                    d3.select(this).transition().duration(400)
                      .attr('fill-opacity', 0)
                      .style("stroke-width", stroke_width);
                }
              })
              .style("opacity", 0)
              .transition()
              .duration(500)
              .delay(function(d, i){return i*50;})
              .style("opacity", 1)
