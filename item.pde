import java.util.ArrayList;

final int ITEM_LINK_LINE_WEIGHT = 1;
final float ITEM_LINK_LINE_WHITENESS = 0.7;

final float TRANSFER_TIME_DEFAULT = 1000;


static ArrayList<Item> items = new ArrayList<Item>();

class Item extends Entity {
  
  Item master;
  ArrayList<Site> links;
  ArrayList<Entity> holders;
  
  final int NOT_MOVING = -1;
  
  float startTime = NOT_MOVING;
  int xInit;
  int yInit;
  int xDest;
  int yDest;
  float duration;
  Entity receiver, sender;
  boolean hidden;
  
  // Create an Item with an initial position and reference to the master copy
  // of this item, used for matching duplicated items
  Item(int x, int y, Item master) {
    super(x, y);
    this.master = master;
    colour = #BBCCFF;
    size = floor(10 * SCALE);
    items.add(this);
    privatelyActive = true;
    links = new ArrayList<Site>();
    holders = new ArrayList<Entity>();
    duration = TRANSFER_TIME_DEFAULT;
  }
  
  Item clone() {
    return new Item(x, y, null).getDetailsFrom(this);
  }
  
  Item getDetailsFrom(Item i) {
    x = i.x;
    y = i.y;
    master = (i.master != null) ? i.master : i;
    links = (ArrayList<Site>) i.links.clone();
    colour = i.colour;
    size = i.size;
    return this;
  }
  
  void sendTo(Entity receiver) {
    sendTo(receiver, null, 0);
  }
  
  void sendTo(Entity receiver, Entity sender, float duration) {
    moveTo(receiver.x, receiver.y, receiver, sender, duration);
  }
  
  // Tell it to move somewhere over a certain period and receiver the receiver
  // when there
  void moveTo(int x, int y, Entity receiver, Entity sender, float duration) {
    xInit = this.x;
    yInit = this.y;
    xDest = x;
    yDest = y;
    this.sender = sender;
    if(duration > 0)
      this.duration = duration;
    this.receiver = receiver;
    if(receiver != null)
      receiver.pendingItem(this); // let them know we are coming
    startTime = millis();
  }
  
  void moveTo(int x, int y) {
    moveTo(x, y, null, null, -1);
  }
  
  void think() {
    if(startTime != NOT_MOVING) {
      float progress = clamp((millis() - startTime) / duration);
      if(progress == 1) {
        x = xDest;
        y = yDest;
        startTime = NOT_MOVING;
        if(receiver != null)
          receiver.acceptItem(this);
        if(sender != null)
          sender.receiverGotItem(this);
      } else {
        progress = ease(progress);
        x = (int) lerp(xInit, xDest, progress);
        y = (int) lerp(yInit, yDest, progress);
      }
    }
  }
  
  void preDraw() {
    if(hidden)
      return;
    
    // draw the links to the other sites
    strokeWeight(max(1, ITEM_LINK_LINE_WEIGHT * SCALE));
    for(Site s : links) {
      stroke(whiten(s.colour, ITEM_LINK_LINE_WHITENESS));
      // we draw the second half in the third pass
      line(lerp(x, s.x, 0.2), lerp(y, s.y, 0.2), s.x, s.y);
    }
  }
  
  void draw() {}
  
  void postDraw() {
    if(hidden)
      return;
    
    // we draw the second half now so it overlaps the site this item may be sitting on
    strokeWeight(max(1, ITEM_LINK_LINE_WEIGHT * SCALE));
    for(Site s : links) {
      stroke(whiten(s.colour, ITEM_LINK_LINE_WHITENESS));
      line(x, y, lerp(x, s.x, 0.2), lerp(y, s.y, 0.2));
    }
    
    fill(colour);
    noStroke();
    ellipse(x, y, size, size);
  }
  
  void remove() {
    super.remove();
    items.remove(this);
    
    // remove ourselves from the list of items each site has
    for(Entity e : (ArrayList<Entity>) holders)
      e.items.remove(this);
  }
  
  // Compares two items, taking inaccount they can be duplicates of each other
  boolean compare(Item i) {
    i = (i.master != null) ? i.master : i;
    return i == this.master || i == this;
  }
  
}

class YouTubeVid extends Item {
  
  YouTubeVid(int x, int y, Item master) {
    super(x, y, master);
    colour = #BB0000;
    links.add(youtube);
  }
  
  YouTubeVid clone() {
    return (YouTubeVid) new YouTubeVid(x, y, null).getDetailsFrom(this);
  }
  
}

class System extends Item {
  
  System(int x, int y, Item master) {
    super(x, y, master);
    colour = #00FF00;
    if(server != null)
      links.add(server);
  }
  
  System clone() {
    return (System) new System(x, y, null).getDetailsFrom(this);
  }
  
  void use() {
    new Data(x, y, null).sendTo(server);
  }
  
}

class Data extends Item {
  
  Data(int x, int y, Item master) {
    super(x, y, master);
    size = floor(5 * SCALE);
    if(server != null)
      colour = server.colour;
  }

}

