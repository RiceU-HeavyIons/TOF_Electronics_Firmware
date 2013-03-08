mux_2x32_registered_inst : mux_2x32_registered PORT MAP (
		clock	 => clock_sig,
		aclr	 => aclr_sig,
		clken	 => clken_sig,
		data1x	 => data1x_sig,
		data0x	 => data0x_sig,
		sel	 => sel_sig,
		result	 => result_sig
	);
