$(function(){
  var canvas = document.getElementById('main_canvas');
  var ctx = canvas.getContext('2d');
  ctx.font = "24px Courier";
  ctx.lineCap = 'round';

  var soldiers = [
    {name: 'Alice', x: 5, y: 5, style: 'soldier 1', hp: 4, hpmax: 4, aim: 65, mobility: 5, actions: 2},
    {name: 'Bob', x: 7, y: 7, style: 'soldier 2', hp: 4, hpmax: 4, aim: 65, mobility: 5, actions: 2},
    {name: 'Charlie', x: 5, y: 7, style: 'soldier 3', hp: 4, hpmax: 4, aim: 65, mobility: 5, actions: 2},
    {name: 'Diana', x: 7, y: 5, style: 'soldier 4', hp: 4, hpmax: 4, aim: 65, mobility: 5, actions: 2},
  ];
  var aliens = [
    {x: 15, y: 12, style: 'sectoid', hp: 3, hpmax: 3, mobility: 5},
    {x: 17, y: 12, style: 'sectoid', hp: 3, hpmax: 3, mobility: 5},
    {x: 16, y: 14, style: 'sectoid', hp: 3, hpmax: 3, mobility: 5},
    {x: 3, y: 3, style: 'muton', hp: 6, hpmax: 6, mobility: 5},
  ];
  var objects = [
    {x: 5, y: 10, style: 'car'},
    {x: 5, y: 11, style: 'car'},
    {x:10, y: 10, style: 'car'},
    {x:10, y: 11, style: 'car'},
    {x:15, y: 10, style: 'car'},
    {x:15, y: 11, style: 'car'},
    {x: 9, y: 3, style: 'wall'},
    {x: 9, y: 4, style: 'wall'},
    {x: 9, y: 5, style: 'door'},
    {x: 9, y: 6, style: 'wall'},
    {x: 9, y: 7, style: 'wall'},
    {x: 16, y: 3, style: 'wall'},
    {x: 16, y: 4, style: 'wall'},
    {x: 16, y: 5, style: 'door'},
    {x: 16, y: 6, style: 'wall'},
    {x: 16, y: 7, style: 'wall'},
    {x: 10, y: 3, style: 'wall'},
    {x: 11, y: 3, style: 'wall'},
    {x: 12, y: 3, style: 'wall'},
    {x: 13, y: 3, style: 'wall'},
    {x: 14, y: 3, style: 'wall'},
    {x: 15, y: 3, style: 'wall'},
    {x: 10, y: 7, style: 'wall'},
    {x: 11, y: 7, style: 'wall'},
    {x: 12, y: 7, style: 'wall'},
    {x: 13, y: 7, style: 'wall'},
    {x: 14, y: 7, style: 'wall'},
    {x: 15, y: 7, style: 'wall'},
  ];
  var current_soldier = 0;
  var mouse_x = 0;
  var mouse_y = 0;

  var styles = {
    'soldier 1': {icon: '1', bg: '#000', fg: '#fff'},
    'soldier 2': {icon: '2', bg: '#000', fg: '#fff'},
    'soldier 3': {icon: '3', bg: '#000', fg: '#fff'},
    'soldier 4': {icon: '4', bg: '#000', fg: '#fff'},
    'sectoid':   {icon: 's', bg: '#800', fg: '#f00'},
    'muton':     {icon: 'm', bg: '#800', fg: '#f00'},
    'berserker': {icon: 'B', bg: '#800', fg: '#f00'},
    'car':       {icon: 'c', bg: '#afa', fg: '#0f0'},
    'wall':      {icon: 'W', bg: '#afa', fg: '#0f0'},
    'door':      {icon: 'D', bg: '#aaf', fg: '#00f'},
    'movement_highlight': {bg: '#ccf'},
  }

  var clear_canvas = function() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  };

  var draw_cell = function(i, j, style) {
    ctx.fillStyle = style;
    ctx.fillRect(i*30+1, j*30+1, 30-2, 30-2);
  };

  var draw_text_sprite = function(obj) {
    var x=obj.x;
    var y=obj.y;
    var style = styles[obj.style];
    draw_cell(x, y, style.bg);
    if(style.icon) {
      ctx.fillStyle = style.fg;
      var xsz = ctx.measureText(style.icon).width;
      ctx.fillText(style.icon, x*30+15-xsz/2, y*30+15+8);
    }
  };

  var draw_all_bounds = function(i, j, style) {
    var x0 = i*30;
    var y0 = j*30;
    ctx.strokeStyle = style;
    ctx.beginPath();
    ctx.moveTo(x0, y0);
    ctx.lineTo(x0+30, y0);
    ctx.lineTo(x0+30, y0+30);
    ctx.lineTo(x0, y0+30);
    ctx.lineTo(x0, y0);
    ctx.stroke();
  };

  var draw_grid = function() {
    ctx.lineWidth = 1;
    for(var i=0; i<20; i++) {
      for(var j=0; j<20; j++) {
        draw_all_bounds(i, j, '#ccc');
      };
    };
  };

  var draw_objects = function() {
    $.each(soldiers, function() { draw_text_sprite(this); });
    $.each(aliens, function() { draw_text_sprite(this); });
    $.each(objects, function() { draw_text_sprite(this); });
  };

  var display_soldier_info = function(soldier) {
    $("#soldier_info").empty();
    $("#soldier_info").append("<div class='name'>Rookie " + soldier.name + "</div>");
    $("#soldier_info").append("<div class='hp'>HP: " + soldier.hp + '/' + soldier.hpmax + "</div>");
    $("#soldier_info").append("<div class='aim'>Aim: " + soldier.aim + "</div>");
    $("#soldier_info").append("<div class='mobility'>Mobility: " + soldier.mobility + "</div>");
    $("#soldier_info").append("<div class='actions'>Actions: " + soldier.actions + "/2</div>");
  };

  var highlight_current_soldier = function() {
    var x = soldiers[current_soldier].x;
    var y = soldiers[current_soldier].y;
    ctx.lineWidth = 3;
    draw_all_bounds(x, y, '#f00');
  };
  var aliens_turn = function() {
    $.each(aliens, function() {
      this.actions = 2;
      this.overwatch = false;
    });
    // TODO: make them actually move
  };
  var start_new_turn = function() {
    $.each(soldiers, function(){
      this.actions = 2;
      this.overwatch = false;
    });
  };

  /****** Actions ******/
  var next_soldier = function() {
    var i = current_soldier + 1;
    while(i != current_soldier) {
      i %= soldiers.length;
      if(soldiers[i].actions > 0) break;
      i += 1;
    };
    if(i == current_soldier) {
      current_soldier = 0;
      end_turn();
    } else {
      current_soldier = i;
    }

  };
  var fire_mode = function() {
    // some ways to let soldiers fire;
  };
  var end_turn = function() {
    aliens_turn();
    start_new_turn();
  };
  var overwatch = function() {
    soldiers[current_soldier].overwatch = true;
    soldiers[current_soldier].actions = 0;
    next_soldier();
  };

  var highlight_mouseover = function() {
    ctx.lineWidth = 2;
    draw_all_bounds(mouse_x, mouse_y, '#00f');
  };

  /* TODO: Doing this function properly is actually fairly nontrivial, this is very dirty approximation */
  var compute_range = function(x0, y0, m) {
    var range = [];
    for(var dy=-m; dy<=m; dy++) {
      for(var dx=-m; dx<=m; dx++) {
        if(dx*dx+dy*dy > m*m) continue;
        var x = x0 + dx;
        var y = y0 + dy;
        if(is_object_present(x, y)) continue;
        range.push({x: x, y: y});
      }
    }
    return range;
  };

  var highlight_current_soldier_range = function() {
    var soldier = soldiers[current_soldier];
    $.each(compute_range(soldier.x, soldier.y, soldier.mobility), function(){
      draw_text_sprite({x:this.x, y:this.y, style:'movement_highlight'});
    });
  };

  var display_available_actions = function() {
    /* TODO: make this soldier specific */
  };
  var find_object = function(x, y) {
    try {
      $.each(soldiers, function(){
        if(this.x === x && this.y === y) {
          throw {type: 'soldier', object: this};
        };
      });
      $.each(aliens, function(){
        if(this.x === x && this.y === y) {
          throw {type: 'alien', object: this};
        };
      });
      $.each(objects, function(){
        if(this.x === x && this.y === y) {
          throw {type: 'object', object: this};
        };
      });
      throw {type: 'empty'};
    } catch(err) {
      // Found the object!
      return err;
    };
  };
  var is_object_present = function(x, y) {
    var found = find_object(x, y);
    return (found.type !== 'empty');
  };
  var display_mouseover_object = function() {
    $("#mouseover_object").empty();
    $("#mouseover_object").append("<div class='coordinates'>x="+mouse_x+" y="+mouse_y+"</div>")
    var found = find_object(mouse_x, mouse_y);
    var object = found.object;
    switch(found.type){
    case 'soldier':
      $("#mouseover_object").append("<div>Rookie "+object.name+"</div>")
      break;
    case 'alien':
      $("#mouseover_object").append("<div>Alien "+object.style+"</div>")
      break;
    case 'object':
      $("#mouseover_object").append("<div>Object "+object.style+"</div>")
      break;
    case 'empty':
      $("#mousover_object").append("<div>Empty</div>")
    }
  };
  var in_range = function(soldier, x, y) {
    var range = compute_range(soldier.x, soldier.y, soldier.mobility);
    try{
      $.each(range, function(){
        if(this.x === x && this.y === this.y) throw "found";
      });
      return false;
    } catch(err) {
      return true;
    }
  }
  var clicked_on = function(x, y) {
    var soldier = soldiers[current_soldier];
    if(in_range(soldier, x, y)) {
      soldier.actions -= 1;
      soldier.x = x;
      soldier.y = y;
      if(soldier.actions == 0) {
        next_soldier();
      }
    }
  };

  var display_info = function() {
    display_soldier_info(soldiers[current_soldier]);
    display_mouseover_object();
    display_available_actions();
  };

  var draw_map = function() {
    clear_canvas();
    draw_grid();
    draw_objects();
    highlight_mouseover();
    highlight_current_soldier();
    highlight_current_soldier_range();

    display_info();
  };

  var main_loop = function() {
    draw_map();
  };
  setInterval(main_loop, 1000.0 / 60.0);
  // TODO: window.requestAnimationFrame(main_loop); ???

  $(canvas).bind("mousemove", function(event) {
    var rect = canvas.getBoundingClientRect();
    mouse_x = Math.floor((event.clientX - rect.left) / 30);
    mouse_y = Math.floor((event.clientY - rect.top) / 30);
  });
  $(canvas).bind("click", function(event) {
    var rect = canvas.getBoundingClientRect();
    var x = Math.floor((event.clientX - rect.left) / 30);
    var y = Math.floor((event.clientY - rect.top) / 30);
    clicked_on(x, y);
  });
  $(document).bind("keypress", function(event) {
    // console.log(event);
    if(event.keyCode == 101) { // 'e' for end turn
      end_turn();
    }
    if(event.keyCode == 102) { // 'f' for fire
      fire_mode();
    }
    if(event.keyCode == 110) { // 'n' for next
      next_soldier();
    }
    if(event.keyCode == 111) { // 'o' for overwatch
      overwatch();
    }
  });
});
