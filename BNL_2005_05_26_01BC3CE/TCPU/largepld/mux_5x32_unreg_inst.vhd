mux_5x32_unreg_inst : mux_5x32_unreg PORT MAP (
		data4x	 => data4x_sig,
		data3x	 => data3x_sig,
		data2x	 => data2x_sig,
		data1x	 => data1x_sig,
		data0x	 => data0x_sig,
		sel	 => sel_sig,
		result	 => result_sig
	);
