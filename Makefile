CONFIG ?= config.default
-include $(CONFIG)

BINARY    ?= wolf3d
PREFIX    ?= /usr/local
DATADIR   ?= $(PREFIX)/share/games/wolf3d/
MANPREFIX ?= $(PREFIX)/share/man/
MANPAGE   ?= man6/wolf4sdl.6

INSTALL         ?= install
INSTALL_PROGRAM ?= $(INSTALL) -m 555 -s
INSTALL_MAN     ?= $(INSTALL) -m 444
INSTALL_DATA    ?= $(INSTALL) -m 444


SDL_CONFIG  ?= sdl2-config
CFLAGS_SDL  ?= $(shell $(SDL_CONFIG) --cflags)
LDFLAGS_SDL ?= $(shell $(SDL_CONFIG) --libs)


CFLAGS += $(CFLAGS_SDL)

#CFLAGS += -Wall
#CFLAGS += -W
CFLAGS += -Wpointer-arith
CFLAGS += -Wreturn-type
CFLAGS += -Wwrite-strings
CFLAGS += -Wcast-align

ifdef GPL
    CFLAGS += -DUSE_GPL
endif

ifdef DATADIR
    CFLAGS += -DDATADIR=\"$(DATADIR)\"
endif

CCFLAGS += $(CFLAGS)
CCFLAGS += -std=gnu99
CCFLAGS += -Werror-implicit-function-declaration
CCFLAGS += -Wimplicit-int
CCFLAGS += -Wsequence-point

CXXFLAGS += $(CFLAGS)

# Add controller mappings
define DOUBLESPACE
  
endef
define SINGLESPACE
 
endef
define SDLDELIMITER
, 
endef
define SDLNEWLINE
,\n
endef
define SDLGREPUNIX
grep -v '^#' SDL_GameControllerDB/gamecontrollerdb.txt
endef
define SDLGREPWINDOWS
findstr /B /V # SDL_GameControllerDB/gamecontrollerdb.txt
endef
SDLGREPCMD := $(if $(filter $(OS),Windows_NT),$(SDLGREPWINDOWS),$(SDLGREPUNIX))
SDLMAPPINGS := $(shell $(SDLGREPCMD))
SDLMAPPINGS := $(subst $(DOUBLESPACE),$(SINGLESPACE),${SDLMAPPINGS})
SDLMAPPINGS := $(subst $(SDLDELIMITER),$(SDLNEWLINE),${SDLMAPPINGS})
CXXFLAGS += -DSDLMAPPINGS="\"$(SDLMAPPINGS)\""

LDFLAGS += $(LDFLAGS_SDL)
LDFLAGS += -lSDL2_mixer
ifneq (,$(findstring MINGW,$(shell uname -s)))
LDFLAGS += -static-libgcc
endif

SRCS :=
ifndef GPL
    SRCS += mame/fmopl.cpp
else
    SRCS += dosbox/dbopl.cpp
endif
SRCS += id_ca.cpp
SRCS += id_in.cpp
SRCS += id_pm.cpp
SRCS += id_sd.cpp
SRCS += id_us_1.cpp
SRCS += id_vh.cpp
SRCS += id_vl.cpp
SRCS += signon.cpp
SRCS += wl_act1.cpp
SRCS += wl_act2.cpp
SRCS += wl_agent.cpp
SRCS += wl_atmos.cpp
SRCS += wl_cloudsky.cpp
SRCS += wl_debug.cpp
SRCS += wl_draw.cpp
SRCS += wl_floorceiling.cpp
SRCS += wl_game.cpp
SRCS += wl_inter.cpp
SRCS += wl_main.cpp
SRCS += wl_menu.cpp
SRCS += wl_parallax.cpp
SRCS += wl_play.cpp
SRCS += wl_state.cpp
SRCS += wl_text.cpp

DEPS = $(filter %.d, $(SRCS:.c=.d) $(SRCS:.cpp=.d))
OBJS = $(filter %.o, $(SRCS:.c=.o) $(SRCS:.cpp=.o))

.SUFFIXES:
.SUFFIXES: .c .cpp .d .o

Q ?= @

all: $(BINARY)

ifndef NO_DEPS
depend: $(DEPS)

ifeq ($(findstring $(MAKECMDGOALS), clean depend Data),)
-include $(DEPS)
endif
endif

$(BINARY): $(OBJS)
	@echo '===> LD $@'
	$(Q)$(CXX) $(CFLAGS) $(OBJS) $(LDFLAGS) -o $@

.c.o:
	@echo '===> CC $<'
	$(Q)$(CC) $(CCFLAGS) -c $< -o $@

.cpp.o:
	@echo '===> CXX $<'
	$(Q)$(CXX) $(CXXFLAGS) -c $< -o $@

.c.d:
	@echo '===> DEP $<'
	$(Q)$(CC) $(CCFLAGS) -MM $< | sed 's#^$(@F:%.d=%.o):#$@ $(@:%.d=%.o):#' > $@

.cpp.d:
	@echo '===> DEP $<'
	$(Q)$(CXX) $(CXXFLAGS) -MM $< | sed 's#^$(@F:%.d=%.o):#$@ $(@:%.d=%.o):#' > $@

clean distclean:
	@echo '===> CLEAN'
	$(Q)rm -fr $(DEPS) $(OBJS) $(BINARY) $(BINARY).exe

install: $(BINARY)
	@echo '===> INSTALL'
	$(Q)$(INSTALL) -d $(PREFIX)/bin
	$(Q)$(INSTALL_PROGRAM) $(BINARY) $(PREFIX)/bin
	$(Q)$(INSTALL_MAN) $(MANPAGE) $(MANPREFIX)/man6
