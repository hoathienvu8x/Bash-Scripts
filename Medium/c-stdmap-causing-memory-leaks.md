---
title: "C++ – std::map causing memory leaks"
link: "https://itecnote.com/tecnote/c-stdmap-causing-memory-leaks/"
---

To make this post a bit more constructive, and let it possibly help others in the future:

The problem was this:

```c++
std::map<Point2, Prop*> mm;
std::pair<Point2, Prop*> p;

if(Keydown(VK_LBUTTON)) {
     p.first = pos; p.second = new Prop();
     mm.insert(p))
}
```

So even though the map would get iterated over and deallocate all the Prop* pointers in the end,
there were times where the insertion would fail (because a pair with the same key might already
be in the tree). That means the new Prop() created, would get orphaned.

**Solutions:**

1) either always use std::shared_ptr (probably best solution)

2) or do this:

```c++
std::map<Point2, Prop*> mm;
std::pair<Point2, Prop*> p;

if(Keydown(VK_LBUTTON)) {
     p.first = pos; p.second = new Prop();
     if(mm.insert(p).second == false) {
          delete p.second;
     }
}
```

Thanks to SO user parapura rajkumar

**Original Question:**

I'm having memory leaks in my application and I don't know what's causing them! I thought
I am deallocating everything I have to. The weird part is: I don't have memory leaks every
time I'm running my application.

In short, this is what my app does:

On initialisation, it creates numRows times numColumns new Tile() inside a TileList.
When the mouse is hovering over some position on the screen, and the left mouse button is
held, it adds a `std::pair<Point2, Prop*> p` , with `p.second = new Prop()` to an `std::map`.

Sometimes I can just add a whole bunch of props and exit the app without any leaks. Sometimes
I would add the same props as before, and it will have memory leaks upon exit.

Please help.
Here is the relevant code:

If you need to see a specific part of my code, just comment it, and I'll edit the question

**PropList.h**

```c++
class PropList
{
protected:
    std::map<Point2, Prop*> m_Props_m;

public:
    PropList(){}
    virtual ~PropList();

    bool PropAdd(std::pair<Point2, Prop*> p)
    {
        pair<map<Point2, Prop*>::iterator,bool> ret = m_Props_m.insert(p);
        return ret.second;
    }
    bool PropRemove( const Point2& pos );
    bool HasProp( const Point2& pos );

    void Tick();

protected:

};

static void PropRelease(const std::pair<Point2, Prop*>& p) {
    delete p.second;
}
```

**PropList.cpp**

```c++
PropList::~PropList()
{
    std::for_each(m_Props_m.begin(), m_Props_m.end(), &PropRelease);
}

bool PropList::PropRemove( const Point2& pos )
{
    std::map<Point2, Prop*>::iterator it = m_Props_m.find(pos);
    if (it == m_Props_m.end()) {
        return false;
    }
    delete (*it).second;
    m_Props_m.erase(it);
    return true;
}
```

**TileList.h**

```c++
class TileList
{
protected:
    std::vector<std::vector<Tile*> > m_Tiles_v;
    PropList m_PropList;

    UINT m_iRowNum;
    UINT m_iColNum;

public:
    TileList(UINT numColumns, UINT numRows);
    virtual ~TileList();

    //Props
    void PropAdd(std::pair<Point2, Prop*> p);
    void PropRemove(const Point2& pos);
    bool HasProp(const Point2& pos);
    void Tick();

    UINT GetNumRows(){return m_iRowNum;}
    UINT GetNumCols(){return m_iColNum;}

protected:
};
```

**TileList.cpp**

```c++
TileList::TileList(UINT numColumns, UINT numRows)
    :m_iRowNum(numRows)
    ,m_iColNum(numColumns)
{
    for (UINT i = 0; i < numRows; ++i) {
        m_Tiles_v.push_back(std::vector<Tile*>());
        for (UINT j = 0; j < numColumns; ++j) {
            m_Tiles_v[i].push_back(new Tile());
        }
    }
}

TileList::~TileList()
{
    BOOST_FOREACH(std::vector<Tile*> col_tiles_v, m_Tiles_v)
    {
        BOOST_FOREACH(Tile* pTile, col_tiles_v)
        {
            delete pTile;
        }
    }
}

void TileList::PropAdd(std::pair<Point2, Prop*> p)
{
    if(m_PropList.PropAdd(p)) {
        m_Tiles_v[p.first.y][p.first.x]->setOccupied(true);
    }
}

void TileList::PropRemove(const Point2& pos) 
{
    if(m_PropList.PropRemove(pos)) {
        m_Tiles_v[pos.y][pos.x]->setOccupied(false);
    }
}
```
