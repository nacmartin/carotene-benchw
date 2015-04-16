erl -K -P 134217727 -pa ebin/ deps/**/ebin/ -boot start_sasl -eval "application:ensure_all_started(carotene_benchw)."
