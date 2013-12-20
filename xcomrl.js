$(function(){
  var canvas = document.getElementById('main_canvas');
  var ctx = canvas.getContext('2d');
  ctx.font = "18px Courier";
  ctx.lineCap = 'round';

  var soldiers = [];
  var aliens = [];
  var objects = [];

  var random_int = function(n) {
    return Math.floor(Math.random() * n);
  };

  /* populate 5x5 level */
  var populate_level_fragment = function(x0,y0) {
    var x = x0 + random_int(4);
    var y = y0 + random_int(4);
    switch(random_int(10)){
      case 0:
      aliens.push({x: x, y: y, style: 'sectoid', hp: 3, hpmax: 3, mobility: 5, aim: 65});
      break;
    case 1:
      aliens.push({x: x, y: y, style: 'muton', hp: 6, hpmax: 6, mobility: 5, aim: 75});
      break;
    case 2:
    case 3:
      objects.push({x: x, y: y, style: 'car'});
      objects.push({x: x, y: y+1, style: 'car'});
      break;
    case 4:
    case 5:
      objects.push({x: x, y: y, style: 'car'});
      objects.push({x: x+1, y: y, style: 'car'});
      break;
    case 6:
    case 7:
      objects.push({x: x0, y: y0, style: 'wall'});
      objects.push({x: x0, y: y0+1, style: 'wall'});
      objects.push({x: x0, y: y0+2, style: 'door'});
      objects.push({x: x0, y: y0+3, style: 'wall'});
      objects.push({x: x0, y: y0+4, style: 'wall'});
      objects.push({x: x0+1, y: y0, style: 'wall'});
      objects.push({x: x0+2, y: y0, style: 'door'});
      objects.push({x: x0+3, y: y0, style: 'wall'});
      objects.push({x: x0+4, y: y0, style: 'wall'});
      break;
    };
  };

  var generate_level = function() {
    soldiers.push({name: 'Alice',   x: 1, y: 1, style: 'soldier 1', hp: 4, hpmax: 4, aim: 65, mobility: 5});
    soldiers.push({name: 'Bob',     x: 3, y: 3, style: 'soldier 2', hp: 4, hpmax: 4, aim: 65, mobility: 5});
    soldiers.push({name: 'Charlie', x: 1, y: 3, style: 'soldier 3', hp: 4, hpmax: 4, aim: 65, mobility: 5});
    soldiers.push({name: 'Diana',   x: 3, y: 1, style: 'soldier 4', hp: 4, hpmax: 4, aim: 65, mobility: 5});
    for(var i=0; i<6; i++)
      for(var j=0; j<6; j++)
        if(i !=0 || j != 0)
          populate_level_fragment(i*5, j*5);
  };
  var current_soldier;
  var mouse_x;
  var mouse_y;
  var current_mode;

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
    'dead':      {icon: 'X', bg: '#000', fg: '#800'},
  }

  var dist2 = function(x,y) {
    return Math.sqrt(x*x+y*y);
  }

  var clear_canvas = function() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  };

  var draw_cell = function(i, j, style) {
    ctx.fillStyle = style;
    ctx.fillRect(i*24+1, j*24+1, 24-2, 24-2);
  };

  var draw_text_sprite = function(obj) {
    var x=obj.x;
    var y=obj.y;
    var style = styles[obj.style];
    draw_cell(x, y, style.bg);
    if(style.icon) {
      ctx.fillStyle = style.fg;
      var xsz = ctx.measureText(style.icon).width;
      ctx.fillText(style.icon, x*24+12-xsz/2, y*24+12+6);
    }
  };

  var draw_all_bounds = function(i, j, style) {
    var x0 = i*24;
    var y0 = j*24;
    ctx.strokeStyle = style;
    ctx.beginPath();
    ctx.moveTo(x0, y0);
    ctx.lineTo(x0+24, y0);
    ctx.lineTo(x0+24, y0+24);
    ctx.lineTo(x0, y0+24);
    ctx.lineTo(x0, y0);
    ctx.stroke();
  };

  var draw_grid = function() {
    ctx.lineWidth = 1;
    for(var i=0; i<30; i++) {
      for(var j=0; j<30; j++) {
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
  var random_move = function(alien) {
    var range = compute_range(alien.x, alien.y, alien.mobility);
    var move = range[random_int(range.length)];
    alien.x = move.x;
    alien.y = move.y;
    alien.actions -= 1;
  };
  var process_alien_actions = function(alien) {
    if(alien.hp == 0) return;
    random_move(alien);
    $.each(soldiers, function() {
      if(in_fire_range(alien, this)){
        fire_action(alien, this);
        return;
      }
    });
    if(alien.actions > 0) random_move(alien);
  };
  var aliens_turn = function() {
    $.each(aliens, function() {
      if(this.hp > 0)
        this.actions = 2;
      else
        this.actions = 0;
      this.overwatch = false;
    });
    $.each(aliens, function() {
      process_alien_actions(this);
    });
  };
  var start_new_turn = function() {
    $.each(soldiers, function(){
      if(this.hp > 0)
        this.actions = 2;
      else
        this.actions = 0;
      this.overwatch = false;
    });
    current_mode = 'move';
    current_soldier = 0;
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
    current_mode = 'move';
  };
  var fire_mode = function() {
    current_mode = 'fire';
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
        if(x<0 || y<0 || x>=30 || y >= 30) continue;
        range.push({x: x, y: y});
      }
    }
    return range;
  };

  var highlight_current_soldier_move_range = function() {
    var soldier = soldiers[current_soldier];
    $.each(compute_range(soldier.x, soldier.y, soldier.mobility), function(){
      draw_text_sprite({x:this.x, y:this.y, style:'movement_highlight'});
    });
  };
  var highlight_current_soldier_fire_range = function() {
    var soldier = soldiers[current_soldier];
    // TODO: highlight
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
    if(mouse_x === null || mouse_y === null) return;
    $("#mouseover_object").append("<div class='coordinates'>x="+mouse_x+" y="+mouse_y+"</div>")
    var found = find_object(mouse_x, mouse_y);
    var object = found.object;
    switch(found.type){
    case 'soldier':
      $("#mouseover_object").append("<div>Rookie "+object.name+" ("+object.hp+"/"+object.hpmax+")</div>");
      break;
    case 'alien':
      $("#mouseover_object").append("<div>Alien "+object.style+" ("+object.hp+"/"+object.hpmax+")</div>");
      if(in_fire_range(soldiers[current_soldier], object)) {
        $("#mouseover_object").append("<div>In range (hit chance "+hit_chance(soldiers[current_soldier], object)+"%)</div>");
      } else {
        $("#mouseover_object").append("<div>Out of range</div>");
      }
      break;
    case 'object':
      $("#mouseover_object").append("<div>Object "+object.style+"</div>");
      break;
    case 'empty':
      $("#mousover_object").append("<div>Empty</div>")
    }
  };
  var in_move_range = function(soldier, x, y) {
    var range = compute_range(soldier.x, soldier.y, soldier.mobility);
    try{
      $.each(range, function(){
        if(this.x === x && this.y === this.y) throw "found";
      });
      return false;
    } catch(err) {
      return true;
    }
  };
  var take_damage = function(target, damage) {
    target.hp -= damage;
    if(target.hp <= 0) {
      target.hp = 0;
      target.style = 'dead';
    }
  }
  var hit_chance = function(shooter, target) {
    var chance = shooter.aim;
    var distance = dist2(shooter.x-target.x, shooter.y-target.y);
    // Aim penalty of up to -20 based on distance
    if(distance >= 5) {
      chance -= Math.round(4*(distance-5));
    }
    // -40 if next to an object (TODO: flanking direction)
    if(find_object(target.x+1, target.y).type === 'object' ||
       find_object(target.x-1, target.y).type === 'object' ||
       find_object(target.x, target.y+1).type === 'object' ||
       find_object(target.x, target.y-1).type === 'object') {
      chance -= 40;
    }
    return chance;
  };
  var fire_action = function(shooter, target) {
    var chance = hit_chance(shooter, target);
    shooter.actions = 0;
    if(Math.random()*100 < chance) {
      take_damage(target, 3);
    }
  };
  var in_fire_range = function(shooter, target) {
    var gun_range = 10;
    var distance = dist2(shooter.x-target.x, shooter.y-target.y);
    return distance <= gun_range;
  };
  var clicked_on = function(x, y) {
    var soldier = soldiers[current_soldier];
    if(current_mode == 'move') {
      if(in_move_range(soldier, x, y)) {
        soldier.x = x;
        soldier.y = y;
        soldier.actions -= 1;
      }
    }
    if(current_mode == 'fire') {
      if(!in_fire_range(soldier, {x:x, y:y})) return;
      var found = find_object(x, y);
      if(found.type !== 'alien') return;
      fire_action(soldier, found.object);
    }
    if(soldier.actions == 0) {
      next_soldier();
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
    if(current_mode == 'move')
      highlight_current_soldier_move_range();
    if(current_mode == 'fire')
      highlight_current_soldier_fire_range();

    display_info();
  };

  $(canvas).bind("mousemove", function(event) {
    var rect = canvas.getBoundingClientRect();
    mouse_x = Math.floor((event.clientX - rect.left) / 24);
    mouse_y = Math.floor((event.clientY - rect.top) / 24);
  });
  $(canvas).bind("click", function(event) {
    var rect = canvas.getBoundingClientRect();
    var x = Math.floor((event.clientX - rect.left) / 24);
    var y = Math.floor((event.clientY - rect.top) / 24);
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

  var main_loop = function() {
    draw_map();
  };
  generate_level();
  start_new_turn();
  setInterval(main_loop, 1000.0 / 60.0);
  // TODO: window.requestAnimationFrame(main_loop); ???
});
