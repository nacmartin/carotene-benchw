PROJECT = carotene_benchw

DEPS = websocket_client jsx
dep_jsx = git git://github.com/talentdeficit/jsx.git v2.4.0
dep_websocket_client = git https://github.com/jeremyong/websocket_client v0.6.1

.PHONY: release clean-release

#release: clean-release all
#	relx -o rel/$(PROJECT)
#
#clean-release:
#	rm -rf rel/$(PROJECT)
#
include erlang.mk

ERLC_OPTS= $(ERLC_COMPILE_OPTS) +debug_info

