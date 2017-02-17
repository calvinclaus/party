require 'curses'
require 'getoptlong'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--farewell', '-f', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--silent', '-s',  GetoptLong::OPTIONAL_ARGUMENT ]
)

silent = false
farewell = false
stuff_to_say = ["Party", "Wo-hoo", "Party", "Yeah"]
opts.each do |opt, arg|
  case opt
  when '--help'
    puts <<~EOF
    party [--silent] ... ["Things", "To", "Say"]

    -h, --help:
      show help

    -f [greeting], --farewell [greeting]:
      says greeting at the end, or "I had a great time" by default

    -s, --silent:
      start a silent party (without MC)
    EOF
    exit()
  when '--farewell'
    if arg == ''
      farewell = "Ei häd äh Grad Tim"
    else
      farewell = arg
    end
  when '--silent'
    silent = true
  end
end

if ARGV.length != 0
  stuff_to_say = ARGV
end


include Curses
class Party

  def self.start(silent, farewell, stuff_to_say)
    interrupted = false
    cols = (%x( tput cols )).to_i
    lines = (%x( tput lines )).to_i
    rec_width = 54
    rec_height = 20
    rec_left_x = cols/2-rec_width/2
    rec_left_y = lines/2-rec_height/2
    init_screen
    start_color
    init_pair(0,COLOR_BLACK, COLOR_YELLOW)
    init_pair(1,COLOR_WHITE, COLOR_BLUE)
    init_pair(2,COLOR_BLACK,COLOR_RED)
    init_pair(3,COLOR_RED,COLOR_BLACK)
    init_pair(4,COLOR_BLACK,COLOR_WHITE)
    init_pair(5,COLOR_BLACK,COLOR_MAGENTA)
    sem = Mutex.new
    talking = Mutex.new
    rect = Thread.new {
      i = 1
      delta = 1
      while !interrupted
        sleep_time = (1.0/i.to_f)*1.3
        sem.synchronize {
          draw_rect(rec_left_x,rec_left_y,rec_width,rec_height, color_pair((i+3)%5), color_pair((i+3)%5), "PARTY")
        }
        sleep(sleep_time)
        sem.synchronize {
          draw_rect(rec_left_x,rec_left_y,rec_width,rec_height, color_pair(1), color_pair(1), "WOHOO")
        }
        sleep(sleep_time)
        i+=delta
        if i == 10 
          delta = -1
        end
        if i == 1
          delta = 1
        end
      end
    }

    saying = Thread.new {
      i = 0
      words = stuff_to_say.cycle
      while !silent
        talking.synchronize{
          system "say", words.next
        }
        i+=1
      end
    }

    bg_lines = Thread.new {
      color = 0
      while !interrupted
        sleep(1)
        i=0
        while i < lines 
          sem.synchronize {
            draw_line(i, lambda { |col, line| rec_left_y <= line && rec_left_y+rec_height >= line && rec_left_x <= col && rec_left_x+rec_width > col})
            refresh
          }
          sleep(0.04)
          i+=1
        end
        sleep(0.5)
        for i in 0..lines
          for j in 0..cols
            sem.synchronize {
              unless rec_left_y <= i && rec_left_y+rec_height >= i && rec_left_x <= j && rec_left_x+rec_width > j
                setpos(i,j)
                attron(color_pair((color%3)+1))
                addstr(" ")
                refresh
              end
            }
            sleep(0.0004)
          end
        end
        color += 1
      end
    }
    trap("INT") {
      rect.kill()
      bg_lines.kill()
      saying.kill()
    }
    bg_lines.join
    rect.join
    saying.join
    close_screen
    if (!silent)
      talking.synchronize {
        if farewell 
          system "say", farewell
        end
      }
    end
  end


  def self.draw_rect(leftX, leftY, l, h, rect_color, text_color, string)
    setpos(leftY, leftX)
    attron(rect_color)
    addstr(spaceStr(l))
    for o in 1..(h-1) 
      setpos(leftY+o, leftX+l-2)
      attron(rect_color)
      addstr("  ")
    end
    for o in 1..(h-1) 
      setpos(leftY+o, leftX)
      addstr("  ")
    end
    setpos(leftY+h,leftX)
    attron(rect_color)
    addstr(spaceStr(l))
    attron(text_color)

    for j in 0..h-2
      setpos(leftY+1+j, leftX+2)
      for o in 1..(l-4)/string.length
        addstr(string)
      end
    end
    refresh
  end


  def self.draw_line(lineNr, should_not_draw)
    setpos(lineNr, 0)
    for i in 0..cols-1
      if (i/3)%3 == 0
        attron(color_pair(5))
      elsif (i/3)%3 == 1
        attron(color_pair(1))
      elsif (i/3)%3 == 2
        attron(color_pair(2))
      end
      unless should_not_draw.call(i, lineNr) 
        setpos(lineNr, i)
        addstr(" ")
      end
    end
  end

  def self.draw_lines_to(lineNr)
    for line in 0..lineNr
      draw_line(line)
    end
  end

  def self.spaceStr(length)
    s = ""
    for _ in 1..length
      s += " "
    end
    return s
  end
end

Party.start(silent, farewell, stuff_to_say)
