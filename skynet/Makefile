include platform.mk

LUA_CLIB_PATH ?= luaclib
CSERVICE_PATH ?= cservice

SKYNET_BUILD_PATH ?= .

CFLAGS = -g -O3 -Wunused-variable -Wall -I$(LUA_INC) $(MYCFLAGS)
#CFLAGS = -g -O0 -Wall -I$(LUA_INC) $(MYCFLAGS)
# CFLAGS += -DUSE_PTHREAD_LOCK

# lua

LUA_STATICLIB := 3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= 3rd/lua

$(LUA_STATICLIB) :
	cd 3rd/lua && $(MAKE) CC='$(CC) -std=gnu99' $(PLAT)

# jemalloc

JEMALLOC_STATICLIB := 3rd/jemalloc/lib/libjemalloc_pic.a
JEMALLOC_INC := 3rd/jemalloc/include/jemalloc

all : jemalloc

.PHONY : jemalloc update3rd

MALLOC_STATICLIB := $(JEMALLOC_STATICLIB)

$(JEMALLOC_STATICLIB) : 3rd/jemalloc/Makefile
	cd 3rd/jemalloc && $(MAKE) CC=$(CC)

3rd/jemalloc/autogen.sh :
	git submodule update --init

3rd/jemalloc/Makefile : | 3rd/jemalloc/autogen.sh
	cd 3rd/jemalloc && ./autogen.sh --with-jemalloc-prefix=je_ --disable-valgrind

jemalloc : $(MALLOC_STATICLIB)

update3rd :
	rm -rf 3rd/jemalloc && git submodule update --init

# skynet

CSERVICE = snlua logger gate harbor
LUA_CLIB = skynet \
  client \
  bson md5 sproto lpeg webclient land lfs majiang tgland 

LUA_CLIB_SKYNET = \
  lua-skynet.c lua-seri.c \
  lua-socket.c \
  lua-mongo.c \
  lua-netpack.c \
  lua-memory.c \
  lua-profile.c \
  lua-multicast.c \
  lua-cluster.c \
  lua-crypt.c lsha1.c \
  lua-sharedata.c \
  lua-stm.c \
  lua-mysqlaux.c \
  lua-debugchannel.c \
  lua-datasheet.c \
  \

SKYNET_SRC = skynet_main.c skynet_handle.c skynet_module.c skynet_mq.c \
  skynet_server.c skynet_start.c skynet_timer.c skynet_error.c \
  skynet_harbor.c skynet_env.c skynet_monitor.c skynet_socket.c socket_server.c \
  malloc_hook.c skynet_daemon.c skynet_log.c

all : \
  $(SKYNET_BUILD_PATH)/skynet \
  $(foreach v, $(CSERVICE), $(CSERVICE_PATH)/$(v).so) \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)
	cd 3rd/lua-cjson && $(MAKE) CC='$(CC) -std=gnu99' PLAT=$(PLAT)
	mv 3rd/lua-cjson/cjson.so luaclib/

$(SKYNET_BUILD_PATH)/skynet : $(foreach v, $(SKYNET_SRC), skynet-src/$(v)) $(LUA_LIB) $(MALLOC_STATICLIB)
	$(CC) $(CFLAGS) -o $@ $^ -Iskynet-src -I$(JEMALLOC_INC) $(LDFLAGS) $(EXPORT) $(SKYNET_LIBS) $(SKYNET_DEFINES)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(CSERVICE_PATH) :
	mkdir $(CSERVICE_PATH)

define CSERVICE_TEMP
  $$(CSERVICE_PATH)/$(1).so : service-src/service_$(1).c | $$(CSERVICE_PATH)
	$$(CC) $$(CFLAGS) $$(SHARED) $$< -o $$@ -Iskynet-src
endef

$(foreach v, $(CSERVICE), $(eval $(call CSERVICE_TEMP,$(v))))

$(LUA_CLIB_PATH)/skynet.so : $(addprefix lualib-src/,$(LUA_CLIB_SKYNET)) | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -Iskynet-src -Iservice-src -Ilualib-src

$(LUA_CLIB_PATH)/bson.so : lualib-src/lua-bson.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Iskynet-src $^ -o $@ -Iskynet-src

$(LUA_CLIB_PATH)/md5.so : 3rd/lua-md5/md5.c 3rd/lua-md5/md5lib.c 3rd/lua-md5/compat-5.2.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lua-md5 $^ -o $@

$(LUA_CLIB_PATH)/client.so : lualib-src/lua-clientsocket.c lualib-src/lua-crypt.c lualib-src/lsha1.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lpthread

$(LUA_CLIB_PATH)/sproto.so : lualib-src/sproto/sproto.c lualib-src/sproto/lsproto.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/sproto $^ -o $@

$(LUA_CLIB_PATH)/lpeg.so : 3rd/lpeg/lpcap.c 3rd/lpeg/lpcode.c 3rd/lpeg/lpprint.c 3rd/lpeg/lptree.c 3rd/lpeg/lpvm.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lpeg $^ -o $@

$(LUA_CLIB_PATH)/rsa.so : 3rd/lua-rsa/lua-rsa.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lua-rsa $^ -o $@  -lssl -lcrypto

$(LUA_CLIB_PATH)/land.so : 3rd/land/GameLogic.cpp 3rd/land/GameUserItemSink.cpp \
							3rd/land/lua-land.cpp 3rd/land/lua-land-def.hpp 3rd/land/GameLogic.h \
							3rd/land/GameUserItemSink.h 3rd/land/CMD_Game.h 3rd/land/CMD_Control.h | $(LUA_CLIB_PATH)
	g++ $(CFLAGS) $(SHARED) -std=c++11 -I3rd/land 3rd/land/GameLogic.cpp 3rd/land/GameUserItemSink.cpp 3rd/land/lua-land.cpp -o $@

$(LUA_CLIB_PATH)/majiang.so : 3rd/majiang/lua-majiang.cpp 3rd/majiang/nor_mj_auto_algorithm_lib.hpp \
							3rd/majiang/nor_mj_auto_algorithm_lib.cpp 3rd/majiang/mj_hu_type_hash.cpp \
							3rd/majiang/mj_jiang_hu_type_hash.cpp 3rd/majiang/majiang.cpp \
							3rd/majiang/mj_hupai_typ_compute.cpp 3rd/majiang/mj_hupai_typ_compute.hpp \
							3rd/majiang/majiang.h 3rd/majiang/lua-majiang-def.hpp | $(LUA_CLIB_PATH)
	g++ $(CFLAGS) $(SHARED) -std=c++11 -I3rd/majiang 3rd/majiang/mj_hupai_typ_compute.cpp 3rd/majiang/nor_mj_auto_algorithm_lib.cpp 3rd/majiang/mj_hu_type_hash.cpp 3rd/majiang/mj_jiang_hu_type_hash.cpp 3rd/majiang/lua-majiang.cpp 3rd/majiang/majiang.cpp -o $@

$(LUA_CLIB_PATH)/tgland.so : 3rd/tgland/lys_card.cpp 3rd/tgland/lys_card.hpp 3rd/tgland/ddz_ai_util.cpp \
							3rd/tgland/pai_struct.h 3rd/tgland/pai_struct.cpp \
							3rd/tgland/fenpai.h 3rd/tgland/fenpai.cpp \
							3rd/tgland/query_map.h 3rd/tgland/query_map.cpp \
							3rd/tgland/type_face_exist_map.h 3rd/tgland/type_face_exist_map.cpp \
							3rd/tgland/ddz_enums.h \
							3rd/tgland/pai_type_map.h 3rd/tgland/pai_type_map.cpp \
							3rd/tgland/ddz_ai_util.hpp 3rd/tgland/ddz_boyi_search.cpp 3rd/tgland/ddz_boyi_search.hpp \
							3rd/tgland/lua-tgland.cpp 3rd/tgland/lua-tgland-def.hpp | $(LUA_CLIB_PATH)
	g++ $(CFLAGS) $(SHARED) -std=c++11 -I3rd/tgland 3rd/tgland/lys_card.cpp 3rd/tgland/ddz_ai_util.cpp \
							3rd/tgland/pai_struct.cpp 3rd/tgland/pai_type_map.cpp \
							3rd/tgland/fenpai.cpp 3rd/tgland/query_map.cpp  3rd/tgland/type_face_exist_map.cpp \
							3rd/tgland/ddz_boyi_search.cpp 3rd/tgland/lua-tgland.cpp -o $@

$(LUA_CLIB_PATH)/lfs.so : 3rd/lfs/lfs.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lfs $^ -o $@

$(LUA_CLIB_PATH)/webclient.so : 3rd/lua-webclient/webclient.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lua-webclient $^ -o $@ -lcurl

clean :
	rm -f $(SKYNET_BUILD_PATH)/skynet $(CSERVICE_PATH)/*.so $(LUA_CLIB_PATH)/*.so

cleanall: clean
ifneq (,$(wildcard 3rd/jemalloc/Makefile))
	cd 3rd/jemalloc && $(MAKE) clean && rm Makefile
endif
	cd 3rd/lua && $(MAKE) clean
	rm -f $(LUA_STATICLIB)
